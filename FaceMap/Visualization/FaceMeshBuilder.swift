import Foundation
import RealityKit
import UIKit
import simd
import os

/// Flagged-region input for the baked heatmap layer.
struct HeatmapInput {
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    let regionDomain: [FacialRegion: FaceDomain]

    var hasFlags: Bool {
        regionSeverity.values.contains { $0 != .normal }
    }

    /// Stable cache-key component: same flags → same baked texture.
    var cacheHash: String {
        regionSeverity
            .map { "\($0.key.rawValue):\($0.value.rawValue):\(regionDomain[$0.key]?.rawValue ?? "-")" }
            .sorted()
            .joined(separator: ",")
    }
}

/// How the mesh surface should be rendered.
struct FaceMeshStyle {
    enum Surface {
        case clay
        case photo
        /// Photo when the capture has projection data and a decodable photo; clay otherwise.
        case automatic
    }
    var surface: Surface = .automatic
    var heatmap: HeatmapInput? = nil
    var castsShadows: Bool = true
    /// Generate collision shapes (calibration tap-picking).
    var generateCollision: Bool = false
}

/// Product of `FaceMeshBuilder.build`. Owns the async texture bakes and the
/// surface/heatmap toggles used by the full-screen viewer.
final class FaceMeshBuildResult {
    /// Rotate/scale this; metric constructions attach here (centroid-centered frame).
    let entity: ModelEntity
    /// Inflated transparent shell carrying the baked heatmap. Child of `entity`;
    /// toggle with `setHeatmapVisible`. Nil when no regions are flagged.
    let heatmapOverlay: ModelEntity?
    /// Centroid used to center the vertices — overlay renderers align in this frame.
    let centroid: SIMD3<Float>
    /// Centered copy of the ORIGINAL 1220-topology vertices (calibration picking).
    let centeredVertices: [SIMD3<Float>]
    /// Await this before snapshotting so photo/heatmap textures are applied.
    private(set) var bakeTask: Task<Void, Never>?

    private let clayMaterial: PhysicallyBasedMaterial
    private var photoMaterial: PhysicallyBasedMaterial?
    /// What the caller currently wants shown — a bake finishing after the user
    /// toggled to clay must not override the toggle.
    private var desiredSurface: FaceMeshStyle.Surface

    /// True once a photo texture is available (drives the viewer's toggle enablement).
    var hasPhotoSurface: Bool { photoMaterial != nil }

    fileprivate init(entity: ModelEntity,
                     heatmapOverlay: ModelEntity?,
                     centroid: SIMD3<Float>,
                     centeredVertices: [SIMD3<Float>],
                     clayMaterial: PhysicallyBasedMaterial,
                     desiredSurface: FaceMeshStyle.Surface) {
        self.entity = entity
        self.heatmapOverlay = heatmapOverlay
        self.centroid = centroid
        self.centeredVertices = centeredVertices
        self.clayMaterial = clayMaterial
        self.desiredSurface = desiredSurface
    }

    func setSurface(_ surface: FaceMeshStyle.Surface) {
        desiredSurface = surface
        applySurface()
    }

    func setHeatmapVisible(_ visible: Bool) {
        heatmapOverlay?.isEnabled = visible
    }

    fileprivate func setPhotoMaterial(_ material: PhysicallyBasedMaterial) {
        photoMaterial = material
        applySurface()
    }

    fileprivate func setBakeTask(_ task: Task<Void, Never>) {
        bakeTask = task
    }

    private func applySurface() {
        let wantsPhoto = desiredSurface != .clay
        if wantsPhoto, let photo = photoMaterial {
            entity.model?.materials = [photo]
        } else {
            entity.model?.materials = [clayMaterial]
        }
    }
}

/// The single mesh builder behind every face-mesh viewport (analysis viewer,
/// thumbnails, calibration, comparison, PDF snapshots). Replaces the duplicate
/// builders that shipped flat-shaded, single-tint meshes:
/// - smooth area-weighted vertex normals (no more faceted shell)
/// - real baked heatmap on an unlit overlay (was: colors averaged to one tint)
/// - photo-textured surface when the capture carries projection data
///
/// The analysis topology contract is inviolate: `face.vertices` and
/// `face.triangleIndices` are never mutated or re-indexed — every derived buffer
/// (centered copies, normals, inflated shell, fallback UVs) is a new array.
enum FaceMeshBuilder {
    private static let logger = Logger(subsystem: "com.fuanne.facemap", category: "FaceMeshBuilder")
    /// Shell inflation for the heatmap overlay: enough to clear z-fighting at every
    /// zoom, small enough to hug the anatomy. (Raise toward 0.001 if grazing-angle
    /// artifacts appear on device.)
    private static let overlayInflation: Float = 0.0006

    static func build(face: CapturedFace,
                      photoJPEG: Data?,
                      style: FaceMeshStyle,
                      cacheKey: String?) -> FaceMeshBuildResult? {
        let raw = face.vertices
        guard !raw.isEmpty, !face.triangleIndices.isEmpty else { return nil }

        let centroid = FaceMeshGeometry.centroid(raw)
        let centered = raw.map { $0 - centroid }
        let normals = FaceMeshGeometry.vertexNormals(positions: centered,
                                                     indices: face.triangleIndices)
        // Mesh UV set: ARKit canonical when the capture recorded it, else a planar
        // front-projection good enough for the low-frequency heatmap on old records.
        let uvs = face.textureCoordinates ?? FaceMeshGeometry.planarUVs(centered)

        guard let resource = makeMesh(name: "face", positions: centered,
                                      normals: normals, uvs: uvs,
                                      indices: face.triangleIndices) else { return nil }

        var clay = PhysicallyBasedMaterial()
        let n = MeshPalette.neutral
        clay.baseColor = .init(tint: UIColor(red: CGFloat(n.x), green: CGFloat(n.y),
                                             blue: CGFloat(n.z), alpha: 1))
        clay.roughness = 0.6
        clay.metallic = 0.0

        let entity = ModelEntity(mesh: resource, materials: [clay])
        if style.generateCollision {
            entity.generateCollisionShapes(recursive: false)
        }

        // Heatmap overlay shell (only when something is flagged).
        var overlay: ModelEntity?
        if let heatmap = style.heatmap, heatmap.hasFlags {
            let inflated = FaceMeshGeometry.inflated(centered, normals: normals,
                                                     by: overlayInflation)
            if let overlayResource = makeMesh(name: "heatmap", positions: inflated,
                                              normals: normals, uvs: uvs,
                                              indices: face.triangleIndices) {
                // Fully transparent until the baked texture lands.
                var placeholder = UnlitMaterial(color: .clear)
                placeholder.blending = .transparent(opacity: 1.0)
                let shell = ModelEntity(mesh: overlayResource, materials: [placeholder])
                entity.addChild(shell)
                overlay = shell
            }
        }

        let result = FaceMeshBuildResult(entity: entity,
                                         heatmapOverlay: overlay,
                                         centroid: centroid,
                                         centeredVertices: centered,
                                         clayMaterial: clay,
                                         desiredSurface: style.surface)

        // Async texture bakes (photo surface + heatmap layer), cache-first.
        let wantsPhoto = style.surface != .clay
            && face.hasPhotoProjectionData
            && photoJPEG != nil
        let heatmap = (overlay != nil) ? style.heatmap : nil
        if wantsPhoto || heatmap != nil {
            result.setBakeTask(startBakes(face: face, photoJPEG: photoJPEG,
                                          wantsPhoto: wantsPhoto, heatmap: heatmap,
                                          centered: centered, normals: normals, uvs: uvs,
                                          cacheKey: cacheKey, result: result))
        }
        return result
    }

    // MARK: - Mesh descriptor

    private static func makeMesh(name: String,
                                 positions: [SIMD3<Float>],
                                 normals: [SIMD3<Float>],
                                 uvs: [SIMD2<Float>],
                                 indices: [Int16]) -> MeshResource? {
        var d = MeshDescriptor(name: name)
        d.positions = MeshBuffers.Positions(positions)
        d.normals = MeshBuffers.Normals(normals)
        if uvs.count == positions.count {
            d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        }
        d.primitives = .triangles(indices.map { UInt32($0) })
        d.materials = .allFaces(0)
        // intentionally silent at the call sites: visual-only fallback — a failed
        // mesh build just shows an empty viewport; indices were validated at decode
        // time in CapturedFace.
        return try? MeshResource.generate(from: [d])
    }

    // MARK: - Texture bakes

    private static func startBakes(face: CapturedFace,
                                   photoJPEG: Data?,
                                   wantsPhoto: Bool,
                                   heatmap: HeatmapInput?,
                                   centered: [SIMD3<Float>],
                                   normals: [SIMD3<Float>],
                                   uvs: [SIMD2<Float>],
                                   cacheKey: String?,
                                   result: FaceMeshBuildResult) -> Task<Void, Never> {
        Task { @MainActor in
            if let heatmap {
                let key = cacheKey.map { "\($0)|heatmap|\(heatmap.cacheHash)" }
                if let texture = await bakedTexture(key: key, semantic: .color, bake: {
                    HeatmapTextureBaker.bake(uvs: uvs,
                                             triangleIndices: face.triangleIndices,
                                             regionSeverity: heatmap.regionSeverity,
                                             regionDomain: heatmap.regionDomain)
                }) {
                    var material = UnlitMaterial()
                    material.color = .init(tint: .white, texture: .init(texture))
                    material.blending = .transparent(opacity: 1.0)
                    result.heatmapOverlay?.model?.materials = [material]
                } else {
                    logger.error("Heatmap bake failed; overlay stays hidden")
                }
            }

            if wantsPhoto, let jpeg = photoJPEG {
                let key = cacheKey.map { "\($0)|photo" }
                if let texture = await bakedTexture(key: key, semantic: .color, bake: {
                    // Projection needs face-local (UNcentered) vertices — the photo
                    // camera transforms are relative to the face anchor's origin, not
                    // the display centroid. Normals are translation-invariant.
                    guard let photo = UIImage(data: jpeg)?.cgImage,
                          let canonicalUVs = face.textureCoordinates,
                          let projection = PhotoUVProjector.project(vertices: face.vertices,
                                                                    normals: normals,
                                                                    face: face)
                    else { return nil }
                    return PhotoTextureBaker.bakeAtlas(photo: photo,
                                                       canonicalUVs: canonicalUVs,
                                                       triangleIndices: face.triangleIndices,
                                                       projection: projection)
                }) {
                    var material = PhysicallyBasedMaterial()
                    material.baseColor = .init(tint: .white, texture: .init(texture))
                    material.roughness = 0.55
                    material.metallic = 0.0
                    result.setPhotoMaterial(material)
                } else {
                    logger.error("Photo texture bake failed; staying on clay surface")
                }
            }
        }
    }

    /// Cache-first texture production: returns the cached `TextureResource`, or runs
    /// `bake` off the main thread and converts + caches the result.
    private static func bakedTexture(key: String?,
                                     semantic: TextureResource.Semantic,
                                     bake: @escaping @Sendable () -> CGImage?) async -> TextureResource? {
        if let key, let cached = FaceTextureCache.texture(forKey: key) {
            return cached
        }
        let image = await Task.detached(priority: .userInitiated) { bake() }.value
        guard let image else { return nil }
        guard let texture = try? TextureResource.generate(
            from: image,
            options: .init(semantic: semantic)
        ) else { return nil }
        if let key { FaceTextureCache.store(texture, forKey: key) }
        return texture
    }
}
