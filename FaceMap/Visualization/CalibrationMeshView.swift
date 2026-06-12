import Foundation
import RealityKit
import SwiftUI
import simd

/// Tappable variant of `FaceMeshOverlay` used in calibration. A tap performs a hit test,
/// finds the closest mesh vertex to the hit point, and reports the vertex index.
/// Pinch and one-finger drag do orbit/zoom (same as `FaceMeshOverlay`).
struct CalibrationMeshView: UIViewRepresentable {
    let face: CapturedFace
    /// Vertex indices that have already been picked. Rendered as small markers on the mesh.
    let pickedIndices: [Int]
    /// Vertex index that should pulse as "currently picked" (most recent), if any.
    let highlightedIndex: Int?
    /// Vertex around which nearby vertex indices are rendered as text labels — the
    /// calibration debug aid described in `FaceLandmarkIndices`. `nil` hides labels.
    let indexLabelCenter: Int?
    let controller: FaceMeshController
    let onVertexTapped: (Int) -> Void

    final class Coordinator: NSObject {
        weak var controller: FaceMeshController?
        weak var entity: ModelEntity?
        weak var markerAnchor: AnchorEntity?
        var faceVertices: [SIMD3<Float>] = []
        var centroid: SIMD3<Float> = .zero
        var onVertexTapped: ((Int) -> Void)?

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view as? ARView,
                  let entity = entity else { return }
            let p = g.location(in: view)
            let hits = view.hitTest(p, query: .nearest, mask: .all)
            guard let hit = hits.first(where: { $0.entity == entity }) ?? hits.first else { return }

            // Convert hit world position into the entity's (centered) local frame, then
            // find the nearest stored vertex.
            let local = entity.convert(position: hit.position, from: nil)
            var bestIdx = 0
            var bestDist: Float = .infinity
            for (i, v) in faceVertices.enumerated() {
                let centered = v - centroid
                let d = simd_distance_squared(local, centered)
                if d < bestDist { bestDist = d; bestIdx = i }
            }
            onVertexTapped?(bestIdx)
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view, let ctrl = controller else { return }
            switch g.state {
            case .began:
                g.setTranslation(.zero, in: view)
            case .changed:
                let t = g.translation(in: view)
                let yaw   = Float(t.x) * .pi / Float(max(view.bounds.width, 1))
                let pitch = Float(t.y) * .pi / Float(max(view.bounds.height, 1))
                ctrl.applyDeltaRotation(yaw: yaw, pitch: pitch)
                g.setTranslation(.zero, in: view)
            default: break
            }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard let ctrl = controller else { return }
            switch g.state {
            case .began:
                g.scale = 1.0
            case .changed:
                let factor = Float(g.scale)
                g.scale = 1.0
                ctrl.applyDeltaScale(factor)
            default: break
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        let c = Coordinator()
        c.controller = controller
        c.onVertexTapped = onVertexTapped
        return c
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        rebuild(into: view, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.controller = controller
        context.coordinator.onVertexTapped = onVertexTapped
        // Markers can change between renders; rebuild just the marker anchor.
        rebuildMarkers(in: uiView, coordinator: context.coordinator)
    }

    // MARK: - Build

    private func rebuild(into view: ARView, coordinator: Coordinator) {
        view.scene.anchors.removeAll()

        guard let (entity, centeredVerts, c) = buildMesh() else { return }
        coordinator.entity = entity
        coordinator.faceVertices = face.vertices
        coordinator.centroid = c

        let anchor = AnchorEntity(world: [0, 0, -0.4])
        anchor.addChild(entity)
        view.scene.addAnchor(anchor)

        let light = DirectionalLight()
        light.light.color = .white
        light.light.intensity = 1500
        light.orientation = simd_quatf(angle: -.pi / 6, axis: [1, 0, 0])
        anchor.addChild(light)

        controller.attach(entity)

        // Marker container — child of the entity so it inherits rotation/scale.
        let markerAnchor = AnchorEntity()
        entity.addChild(markerAnchor)
        coordinator.markerAnchor = markerAnchor
        _ = centeredVerts                      // capture not needed; vertices live on coordinator
        rebuildMarkers(in: view, coordinator: coordinator)
    }

    private func rebuildMarkers(in view: ARView, coordinator: Coordinator) {
        guard let markerAnchor = coordinator.markerAnchor else { return }
        markerAnchor.children.removeAll()

        let verts = coordinator.faceVertices
        let centroid = coordinator.centroid

        for idx in pickedIndices where idx < verts.count {
            let isHighlighted = (idx == highlightedIndex)
            let pos = verts[idx] - centroid
            let radius: Float = isHighlighted ? 0.0035 : 0.0025
            let mesh = MeshResource.generateSphere(radius: radius)
            var mat = UnlitMaterial(color: isHighlighted ? .systemGreen : .systemYellow)
            mat.blending = .opaque
            let marker = ModelEntity(mesh: mesh, materials: [mat])
            marker.position = pos
            markerAnchor.addChild(marker)
        }

        addIndexLabels(to: markerAnchor, verts: verts, centroid: centroid)
    }

    /// Labels the vertices nearest `indexLabelCenter` with their indices so the
    /// practitioner can read exact vertex numbers while calibrating.
    private func addIndexLabels(to markerAnchor: AnchorEntity,
                                verts: [SIMD3<Float>],
                                centroid: SIMD3<Float>) {
        guard let center = indexLabelCenter, center < verts.count else { return }
        let centerPos = verts[center]
        let nearest = verts.indices
            .map { (idx: $0, d: simd_distance_squared(verts[$0], centerPos)) }
            .sorted { $0.d < $1.d }
            .prefix(16)
        for (idx, _) in nearest {
            markerAnchor.addChild(Self.indexLabel(idx, position: verts[idx] - centroid))
        }
    }

    private static func indexLabel(_ index: Int, position: SIMD3<Float>) -> ModelEntity {
        let textMesh = MeshResource.generateText(
            String(index),
            extrusionDepth: 0,
            font: .systemFont(ofSize: 8, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        var mat = UnlitMaterial(color: .cyan)
        mat.blending = .opaque
        let entity = ModelEntity(mesh: textMesh, materials: [mat])

        let s: Float = 0.0005
        entity.scale = SIMD3<Float>(repeating: s)

        // Push slightly off the surface (radially from mesh centre) to avoid z-fighting.
        let outward = simd_length(position) > 1e-6
            ? simd_normalize(position)
            : SIMD3<Float>(0, 0, 1)
        entity.position = position + outward * 0.003

        // Centre horizontally — generateText anchors at the bottom-left.
        let bounds = entity.visualBounds(relativeTo: entity)
        entity.position.x -= bounds.extents.x / 2 * s

        entity.components.set(LabelBillboardComponent())
        return entity
    }

    /// Returns the model entity, the centered vertex array used for picking, and the centroid.
    private func buildMesh() -> (ModelEntity, [SIMD3<Float>], SIMD3<Float>)? {
        let raw = face.vertices
        guard !raw.isEmpty, !face.triangleIndices.isEmpty else { return nil }

        let centroid = raw.reduce(SIMD3<Float>(repeating: 0), +) / Float(raw.count)
        let centered = raw.map { $0 - centroid }

        var d = MeshDescriptor(name: "calibrationFace")
        d.positions = MeshBuffers.Positions(centered)
        d.primitives = .triangles(face.triangleIndices.map { UInt32($0) })
        d.materials = .allFaces(0)

        guard let resource = try? MeshResource.generate(from: [d]) else { return nil }

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(white: 0.78, alpha: 1))
        material.roughness = 0.7
        material.metallic = 0.0

        let entity = ModelEntity(mesh: resource, materials: [material])
        entity.generateCollisionShapes(recursive: false)
        return (entity, centered, centroid)
    }
}
