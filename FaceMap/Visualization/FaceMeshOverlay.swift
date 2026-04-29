import Foundation
import RealityKit
import SwiftUI
import simd

/// Renders a `CapturedFace` as a static 3D mesh in a RealityKit scene.
/// Used on the analysis screen so the practitioner can rotate the captured mesh
/// after the live AR session ends. Vertex colors come from the heatmap.
struct FaceMeshOverlay: UIViewRepresentable {
    let face: CapturedFace
    let regionSeverity: [FacialRegion: MetricResult.Severity]

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)
        rebuild(into: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        rebuild(into: uiView)
    }

    private func rebuild(into view: ARView) {
        view.scene.anchors.removeAll()

        guard let entity = try? buildMeshEntity() else { return }
        let anchor = AnchorEntity(world: [0, 0, -0.45])
        anchor.addChild(entity)
        view.scene.addAnchor(anchor)

        let light = DirectionalLight()
        light.light.color = .white
        light.light.intensity = 1500
        light.orientation = simd_quatf(angle: -.pi / 6, axis: [1, 0, 0])
        anchor.addChild(light)
    }

    private func buildMeshEntity() throws -> Entity {
        let verts = face.vertices
        guard !verts.isEmpty, !face.triangleIndices.isEmpty else {
            return Entity()
        }

        var descriptor = MeshDescriptor(name: "face")
        descriptor.positions = MeshBuffers.Positions(verts)
        descriptor.primitives = .triangles(face.triangleIndices.map { UInt32($0) })

        // Per-vertex color tinted by region severity; default neutral if not in any region.
        let colors = vertexColors(vertexCount: verts.count)
        descriptor.materials = MeshDescriptor.Materials.allFaces(0)
        var resource = try MeshResource.generate(from: [descriptor])

        // Apply vertex colors via a custom material part. RealityKit's PhysicallyBasedMaterial
        // doesn't expose direct vertex colors on iOS 17, so we approximate by averaging the
        // dominant region color into the base color. For per-vertex shading we'd switch to
        // CustomMaterial with a Metal shader — out of scope for v0.1.
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: dominantTint(colors: colors))
        material.roughness = 0.7
        material.metallic = 0.0

        let entity = ModelEntity(mesh: resource, materials: [material])
        // Center the mesh by translating its centroid to the origin.
        let centroid = verts.reduce(SIMD3<Float>(repeating: 0), +) / Float(max(verts.count, 1))
        entity.position = -centroid
        entity.scale = [3.0, 3.0, 3.0]
        return entity
    }

    private func vertexColors(vertexCount: Int) -> [SIMD4<Float>] {
        var colors = Array(repeating: SIMD4<Float>(0.85, 0.78, 0.72, 1), count: vertexCount)
        for (region, severity) in regionSeverity {
            guard let indices = FaceLandmarkIndices.regionVertices[region] else { continue }
            let c = severity.tint
            for i in indices where i >= 0 && i < vertexCount {
                colors[i] = c
            }
        }
        return colors
    }

    private func dominantTint(colors: [SIMD4<Float>]) -> UIColor {
        let avg = colors.reduce(SIMD4<Float>(repeating: 0), +) / Float(max(colors.count, 1))
        return UIColor(red: CGFloat(avg.x), green: CGFloat(avg.y), blue: CGFloat(avg.z), alpha: 1)
    }
}

private extension MetricResult.Severity {
    var tint: SIMD4<Float> {
        switch self {
        case .normal:      return SIMD4(0.78, 0.86, 0.78, 1)
        case .mild:        return SIMD4(0.95, 0.85, 0.55, 1)
        case .moderate:    return SIMD4(0.95, 0.65, 0.40, 1)
        case .significant: return SIMD4(0.90, 0.30, 0.30, 1)
        }
    }
}
