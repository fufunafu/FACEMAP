import Foundation
import CoreGraphics
import simd

/// CPU rasterizer that bakes the per-vertex region/severity heatmap into a texture
/// in mesh-UV space. Replaces the old `dominantTint` approach, which averaged the
/// per-vertex colors into ONE uniform tint for the whole mesh.
///
/// The baked texture rides on a slightly inflated, unlit, transparent overlay shell
/// (see `FaceMeshBuilder`) so severity hues stay lighting-independent and legible,
/// work over both clay and photo surfaces, and toggle without a rebake.
enum HeatmapTextureBaker {

    /// UV→texel convention for ALL bakers (single source of truth, per the plan's
    /// "isolate every image↔UV conversion" rule): u→x left-to-right, v=0 at the
    /// BOTTOM row (USD/GL convention, matching RealityKit's sampling of
    /// `MeshDescriptor.textureCoordinates`). If device verification shows the bake
    /// V-flipped, this is the one line to change.
    static func texelXY(u: Float, v: Float, size: Int) -> (x: Float, y: Float) {
        (u * Float(size - 1), (1 - v) * Float(size - 1))
    }

    /// Bakes the heatmap. Pure CPU work — call off the main thread; only the
    /// `TextureResource` conversion needs the main actor.
    ///
    /// Per-vertex color: flagged-region vertices get the pure domain hue with
    /// alpha = severity mix (so compositing over the clay tint reproduces the old
    /// `meshTint` blend exactly, and over a photo it tints proportionally).
    /// Unflagged vertices are fully transparent.
    static func bake(uvs: [SIMD2<Float>],
                     triangleIndices: [Int16],
                     regionSeverity: [FacialRegion: MetricResult.Severity],
                     regionDomain: [FacialRegion: FaceDomain],
                     size: Int = 512) -> CGImage? {
        guard !uvs.isEmpty, !triangleIndices.isEmpty, size > 1 else { return nil }

        // 1. Per-vertex RGBA (straight alpha).
        var colors = Array(repeating: SIMD4<Float>(repeating: 0), count: uvs.count)
        for (region, severity) in regionSeverity {
            guard let indices = FaceLandmarkIndices.regionVertices[region] else { continue }
            let domain = regionDomain[region] ?? .symmetry
            let hue = domain.hueRGB
            let alpha = domain.severityMix(severity)
            guard alpha > 0 else { continue }
            for i in indices where i >= 0 && i < colors.count {
                colors[i] = SIMD4(hue.x, hue.y, hue.z, alpha)
            }
        }
        guard colors.contains(where: { $0.w > 0 }) else { return nil }

        // 2. Rasterize triangles in UV space with barycentric color interpolation.
        var buffer = RasterBuffer(size: size)
        var t = 0
        while t + 2 < triangleIndices.count {
            let i0 = Int(triangleIndices[t]), i1 = Int(triangleIndices[t + 1]), i2 = Int(triangleIndices[t + 2])
            t += 3
            guard i0 < uvs.count, i1 < uvs.count, i2 < uvs.count else { continue }
            buffer.fillTriangle(
                p0: texelXY(u: uvs[i0].x, v: uvs[i0].y, size: size),
                p1: texelXY(u: uvs[i1].x, v: uvs[i1].y, size: size),
                p2: texelXY(u: uvs[i2].x, v: uvs[i2].y, size: size),
                c0: colors[i0], c1: colors[i1], c2: colors[i2]
            )
        }

        // 3. One dilation pass so bilinear sampling at triangle edges doesn't bleed
        //    the transparent background into the painted area.
        buffer.dilate()

        return buffer.makeImage()
    }
}

/// RGBA8 (premultiplied) scanline raster target shared by the texture bakers.
struct RasterBuffer {
    let size: Int
    /// RGBA8, premultiplied alpha, row 0 at the top (CGImage layout).
    private(set) var pixels: [UInt8]
    /// Coverage mask for the dilation pass.
    private var covered: [Bool]

    init(size: Int) {
        self.size = size
        self.pixels = Array(repeating: 0, count: size * size * 4)
        self.covered = Array(repeating: false, count: size * size)
    }

    /// Bounding-box barycentric fill with per-vertex color interpolation.
    /// Coordinates are texel-space (x right, y down — callers convert UVs first).
    mutating func fillTriangle(p0: (x: Float, y: Float),
                               p1: (x: Float, y: Float),
                               p2: (x: Float, y: Float),
                               c0: SIMD4<Float>, c1: SIMD4<Float>, c2: SIMD4<Float>) {
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
                // Small negative tolerance keeps texels on shared triangle edges
                // from falling through both triangles' coverage tests.
                guard w0 >= -0.001, w1 >= -0.001, w2 >= -0.001 else { continue }
                let color = c0 * max(w0, 0) + c1 * max(w1, 0) + c2 * max(w2, 0)
                write(x: x, y: y, rgba: color)
            }
        }
    }

    mutating func write(x: Int, y: Int, rgba: SIMD4<Float>) {
        let index = (y * size + x)
        let base = index * 4
        let a = min(max(rgba.w, 0), 1)
        // Premultiplied.
        pixels[base]     = UInt8(min(max(rgba.x * a, 0), 1) * 255)
        pixels[base + 1] = UInt8(min(max(rgba.y * a, 0), 1) * 255)
        pixels[base + 2] = UInt8(min(max(rgba.z * a, 0), 1) * 255)
        pixels[base + 3] = UInt8(a * 255)
        covered[index] = true
    }

    /// One 3×3 pass copying each covered texel into uncovered neighbors, so
    /// bilinear sampling at UV-island edges reads the island color, not background.
    mutating func dilate() {
        let source = pixels
        let sourceCovered = covered
        for y in 0..<size {
            for x in 0..<size {
                let index = y * size + x
                guard !sourceCovered[index] else { continue }
                inner: for dy in -1...1 {
                    for dx in -1...1 where dx != 0 || dy != 0 {
                        let nx = x + dx, ny = y + dy
                        guard nx >= 0, nx < size, ny >= 0, ny < size else { continue }
                        let n = ny * size + nx
                        if sourceCovered[n] {
                            for k in 0..<4 { pixels[index * 4 + k] = source[n * 4 + k] }
                            break inner
                        }
                    }
                }
            }
        }
    }

    /// Sample without dilation bookkeeping — used by tests.
    func rgba(x: Int, y: Int) -> SIMD4<Float> {
        let base = (y * size + x) * 4
        return SIMD4(Float(pixels[base]) / 255, Float(pixels[base + 1]) / 255,
                     Float(pixels[base + 2]) / 255, Float(pixels[base + 3]) / 255)
    }

    func makeImage() -> CGImage? {
        let data = Data(pixels)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(width: size, height: size,
                       bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: size * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil,
                       shouldInterpolate: true, intent: .defaultIntent)
    }
}
