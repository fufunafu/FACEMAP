import Foundation
import CoreGraphics
import simd

/// Per-vertex projection of the mesh into the stored clinical photo, plus the atlas
/// baker that turns the photo into a canonical-UV texture for the mesh.
enum PhotoUVProjector {

    struct PhotoProjection {
        /// Normalized top-left-origin UV into the stored (portrait, unmirrored)
        /// photo, per vertex. May lie outside 0...1; NaN marks behind-camera.
        let imageUV: [SIMD2<Float>]
        /// saturate(dot(worldNormal, dirToCamera)) — 0 for backfacing vertices.
        let visibility: [Float]
    }

    /// Projects every vertex through the capture-time camera. Returns nil when the
    /// capture lacks the photo-projection fields (legacy records) — the all-or-
    /// nothing contract on `CapturedFace.hasPhotoProjectionData`.
    ///
    /// Uses `FaceTextureProjection.photoUV` (the capture↔render contract) — the
    /// projection math lives there and only there.
    static func project(vertices: [SIMD3<Float>],
                        normals: [SIMD3<Float>],
                        face: CapturedFace) -> PhotoProjection? {
        guard let photoFaceTransform = face.photoFaceTransform,
              let cameraTransform = face.cameraTransform,
              let intrinsics = face.cameraIntrinsics,
              let resolution = face.rawImageResolution else { return nil }

        let cameraPosition = SIMD3(cameraTransform.columns.3.x,
                                   cameraTransform.columns.3.y,
                                   cameraTransform.columns.3.z)
        // Rotation part of face→world for transforming normals (rigid, so the
        // rotation submatrix is orthonormal — no inverse-transpose needed).
        let rotation = simd_float3x3(
            SIMD3(photoFaceTransform.columns.0.x, photoFaceTransform.columns.0.y, photoFaceTransform.columns.0.z),
            SIMD3(photoFaceTransform.columns.1.x, photoFaceTransform.columns.1.y, photoFaceTransform.columns.1.z),
            SIMD3(photoFaceTransform.columns.2.x, photoFaceTransform.columns.2.y, photoFaceTransform.columns.2.z)
        )

        var imageUV: [SIMD2<Float>] = []
        imageUV.reserveCapacity(vertices.count)
        var visibility: [Float] = []
        visibility.reserveCapacity(vertices.count)

        for (i, vertex) in vertices.enumerated() {
            if let uv = FaceTextureProjection.photoUV(vertex: vertex,
                                                      photoFaceTransform: photoFaceTransform,
                                                      cameraTransform: cameraTransform,
                                                      intrinsics: intrinsics,
                                                      rawImageResolution: resolution) {
                imageUV.append(uv)
                let world4 = photoFaceTransform * SIMD4(vertex.x, vertex.y, vertex.z, 1)
                let worldPosition = SIMD3(world4.x, world4.y, world4.z)
                let worldNormal = rotation * (i < normals.count ? normals[i] : SIMD3(0, 0, 1))
                let toCamera = simd_normalize(cameraPosition - worldPosition)
                visibility.append(max(0, simd_dot(worldNormal, toCamera)))
            } else {
                imageUV.append(SIMD2(Float.nan, Float.nan))
                visibility.append(0)
            }
        }
        return PhotoProjection(imageUV: imageUV, visibility: visibility)
    }
}

/// Bakes the clinical photo into a canonical-UV atlas: per texel, interpolate the
/// projected photo UV + visibility across the triangle, sample the photo, and blend
/// toward the neutral clay tint as visibility falls off. Baking (rather than putting
/// projected UVs directly on the mesh) is what prevents backfacing/steep-angle
/// texels from smearing stretched ear/cheek pixels across the hidden side — they
/// fade to clay instead.
enum PhotoTextureBaker {

    /// Pure CPU work — call off the main thread.
    /// - Parameters:
    ///   - canonicalUVs: mesh UV set (ARKit canonical) the atlas is laid out in.
    ///   - projection: per-vertex photo UVs + visibility from `PhotoUVProjector`.
    static func bakeAtlas(photo: CGImage,
                          canonicalUVs: [SIMD2<Float>],
                          triangleIndices: [Int16],
                          projection: PhotoUVProjector.PhotoProjection,
                          size: Int = 1024) -> CGImage? {
        guard canonicalUVs.count == projection.imageUV.count,
              !triangleIndices.isEmpty, size > 1 else { return nil }
        guard let sampler = ImageSampler(photo) else { return nil }

        let neutral = MeshPalette.neutral
        var buffer = RasterBuffer(size: size)

        var t = 0
        while t + 2 < triangleIndices.count {
            let i0 = Int(triangleIndices[t]), i1 = Int(triangleIndices[t + 1]), i2 = Int(triangleIndices[t + 2])
            t += 3
            guard i0 < canonicalUVs.count, i1 < canonicalUVs.count, i2 < canonicalUVs.count else { continue }

            let p0 = HeatmapTextureBaker.texelXY(u: canonicalUVs[i0].x, v: canonicalUVs[i0].y, size: size)
            let p1 = HeatmapTextureBaker.texelXY(u: canonicalUVs[i1].x, v: canonicalUVs[i1].y, size: size)
            let p2 = HeatmapTextureBaker.texelXY(u: canonicalUVs[i2].x, v: canonicalUVs[i2].y, size: size)

            let uv0 = projection.imageUV[i0], uv1 = projection.imageUV[i1], uv2 = projection.imageUV[i2]
            let v0 = projection.visibility[i0], v1 = projection.visibility[i1], v2 = projection.visibility[i2]
            // A triangle with any behind-camera vertex can't be interpolated safely.
            let degenerate = uv0.x.isNaN || uv1.x.isNaN || uv2.x.isNaN

            buffer.fillTriangleCustom(p0: p0, p1: p1, p2: p2) { w0, w1, w2 in
                guard !degenerate else { return neutral }
                let uv = uv0 * w0 + uv1 * w1 + uv2 * w2
                let visibility = v0 * w0 + v1 * w1 + v2 * w2
                var weight = smoothstep(0.15, 0.45, visibility)
                if uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1 { weight = 0 }
                guard weight > 0 else { return neutral }
                let photoColor = sampler.bilinear(u: uv.x, v: uv.y)
                let blended = photoColor * weight + neutral * (1 - weight)
                return SIMD4(blended.x, blended.y, blended.z, 1)
            }
        }

        buffer.dilate()
        return buffer.makeImage()
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

extension RasterBuffer {
    /// Barycentric fill where the caller computes each texel's color from the
    /// interpolation weights. Same coverage rules as `fillTriangle`.
    mutating func fillTriangleCustom(p0: (x: Float, y: Float),
                                     p1: (x: Float, y: Float),
                                     p2: (x: Float, y: Float),
                                     shade: (Float, Float, Float) -> SIMD4<Float>) {
        let minX = max(0, Int(min(p0.x, p1.x, p2.x).rounded(.down)))
        let maxX = min(size - 1, Int(max(p0.x, p1.x, p2.x).rounded(.up)))
        let minY = max(0, Int(min(p0.y, p1.y, p2.y).rounded(.down)))
        let maxY = min(size - 1, Int(max(p0.y, p1.y, p2.y).rounded(.up)))
        guard minX <= maxX, minY <= maxY else { return }

        let denom = (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
        guard abs(denom) > 1e-9 else { return }

        for y in minY...maxY {
            for x in minX...maxX {
                let px = Float(x), py = Float(y)
                let w0 = ((p1.y - p2.y) * (px - p2.x) + (p2.x - p1.x) * (py - p2.y)) / denom
                let w1 = ((p2.y - p0.y) * (px - p2.x) + (p0.x - p2.x) * (py - p2.y)) / denom
                let w2 = 1 - w0 - w1
                guard w0 >= -0.001, w1 >= -0.001, w2 >= -0.001 else { continue }
                write(x: x, y: y, rgba: shade(max(w0, 0), max(w1, 0), max(w2, 0)))
            }
        }
    }
}

/// RGBA8 snapshot of a CGImage with bilinear sampling in normalized top-left-origin
/// UV — matches `FaceTextureProjection.photoUV`'s output convention.
struct ImageSampler {
    let width: Int
    let height: Int
    private let pixels: [UInt8]

    init?(_ image: CGImage) {
        width = image.width
        height = image.height
        guard width > 0, height > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &buffer,
                                      width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        pixels = buffer
    }

    /// Bilinear sample; (0,0) is the image's top-left, matching photo UV convention.
    func bilinear(u: Float, v: Float) -> SIMD4<Float> {
        let fx = min(max(u, 0), 1) * Float(width - 1)
        let fy = min(max(v, 0), 1) * Float(height - 1)
        let x0 = Int(fx), y0 = Int(fy)
        let x1 = min(x0 + 1, width - 1), y1 = min(y0 + 1, height - 1)
        let tx = fx - Float(x0), ty = fy - Float(y0)

        func at(_ x: Int, _ y: Int) -> SIMD4<Float> {
            let base = (y * width + x) * 4
            return SIMD4(Float(pixels[base]) / 255, Float(pixels[base + 1]) / 255,
                         Float(pixels[base + 2]) / 255, Float(pixels[base + 3]) / 255)
        }

        let top = at(x0, y0) * (1 - tx) + at(x1, y0) * tx
        let bottom = at(x0, y1) * (1 - tx) + at(x1, y1) * tx
        return top * (1 - ty) + bottom * ty
    }
}
