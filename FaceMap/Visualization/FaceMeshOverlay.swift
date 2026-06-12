import Foundation
import RealityKit
import SwiftUI
import simd

/// Holds the captured-mesh view's transform state and applies it to the live `ModelEntity`.
/// Owned by `AnalysisScreen` as a `@StateObject` so preset-view buttons and gesture
/// handlers mutate the same instance. Has no `@Published` properties — mutations write
/// directly to the entity, so SwiftUI does not re-render the whole overlay on each frame.
final class FaceMeshController: ObservableObject {
    internal weak var entity: ModelEntity?

    private var yaw: Float = 0
    private var pitch: Float = 0
    private var scaleMul: Float = 1.0
    private let baseScale: Float = 3.0
    private let pitchClamp: Float = 1.4

    internal func attach(_ entity: ModelEntity) {
        self.entity = entity
        applyTransform()
    }

    func reset() {
        yaw = 0; pitch = 0; scaleMul = 1.0
        applyTransform()
    }

    func setPreset(_ preset: FaceViewPreset) {
        yaw = preset.yaw
        pitch = preset.pitch
        // Keep the user's current zoom across preset jumps.
        applyTransform()
    }

    internal func applyDeltaRotation(yaw dy: Float, pitch dp: Float) {
        yaw += dy
        pitch = max(-pitchClamp, min(pitchClamp, pitch + dp))
        applyTransform()
    }

    internal func applyDeltaScale(_ factor: Float) {
        scaleMul = max(0.4, min(4.0, scaleMul * factor))
        applyTransform()
    }

    private func applyTransform() {
        guard let entity = entity else { return }
        let q = simd_quatf(angle: yaw,   axis: [0, 1, 0]) *
                simd_quatf(angle: pitch, axis: [1, 0, 0])
        entity.orientation = q
        let s = baseScale * scaleMul
        entity.scale = SIMD3<Float>(s, s, s)
    }
}

/// Canonical viewing angles practitioners use for treatment planning photos.
enum FaceViewPreset: String, CaseIterable, Identifiable {
    case front
    case threeQuarterL
    case threeQuarterR
    case profileL
    case profileR
    case top

    var id: String { rawValue }

    var label: String {
        switch self {
        case .front:         return "Front"
        case .threeQuarterL: return "¾ L"
        case .threeQuarterR: return "¾ R"
        case .profileL:      return "L"
        case .profileR:      return "R"
        case .top:           return "Top"
        }
    }

    var yaw: Float {
        switch self {
        case .front, .top:   return 0
        case .threeQuarterL: return  .pi / 4
        case .threeQuarterR: return -.pi / 4
        case .profileL:      return  .pi / 2
        case .profileR:      return -.pi / 2
        }
    }

    var pitch: Float {
        self == .top ? -.pi / 3 : 0
    }
}

/// Renders a `CapturedFace` as a static 3D mesh. One-finger drag orbits in yaw/pitch
/// around the centroid; pinch zooms. No translation — the camera stays put.
struct FaceMeshOverlay: UIViewRepresentable {
    let face: CapturedFace
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    /// Domain that "owns" each flagged region (drives tint hue).
    /// Defaults to `.symmetry` for any region not present.
    var regionDomain: [FacialRegion: FaceDomain] = [:]
    let controller: FaceMeshController
    /// When `false`, no pan/pinch gesture recognisers are attached. Use for thumbnail
    /// previews embedded in scrollable layouts so the mesh doesn't intercept scrolling.
    var interactive: Bool = true
    /// Background colour of the RealityKit viewport. Defaults to `Theme.meshCanvas` (black —
    /// the deliberate "spotlight" treatment used in the full-screen viewer). Pass
    /// `Theme.surface` for thumbnail previews that should blend into a card.
    var backgroundColor: UIColor = UIColor(Theme.meshCanvas)
    /// Per-metric geometric overlays (markers, lines, billboard labels) rendered on
    /// top of the mesh. Empty = clean mesh. Built via the `VisuallyExplainable` protocol.
    var constructions: [MetricConstruction] = []

    final class Coordinator: NSObject {
        weak var controller: FaceMeshController?

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
        return c
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(backgroundColor)

        if interactive {
            let pan = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            view.addGestureRecognizer(pan)

            let pinch = UIPinchGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePinch(_:))
            )
            view.addGestureRecognizer(pinch)
        }

        rebuild(into: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Keep the coordinator pointing at the current controller, but do NOT rebuild.
        // The mesh is built once in makeUIView; gestures mutate the entity directly.
        context.coordinator.controller = controller
    }

    private func rebuild(into view: ARView) {
        view.scene.anchors.removeAll()
        guard let (entity, centroid) = buildMeshEntity() else { return }

        let anchor = AnchorEntity(world: [0, 0, -0.4])
        anchor.addChild(entity)
        view.scene.addAnchor(anchor)

        let light = DirectionalLight()
        light.light.color = .white
        light.light.intensity = 1500
        light.orientation = simd_quatf(angle: -.pi / 6, axis: [1, 0, 0])
        anchor.addChild(light)

        if !constructions.isEmpty {
            MetricConstructionRenderer.render(
                constructions, on: entity, centroid: centroid
            )
        }

        controller.attach(entity)
    }

    /// Build a `ModelEntity` whose vertices are pre-centered on the face centroid,
    /// so rotation and scale pivot around the centroid. Returns the entity AND the
    /// centroid that was used so overlay renderers can align in the same frame.
    private func buildMeshEntity() -> (ModelEntity, SIMD3<Float>)? {
        let raw = face.vertices
        guard !raw.isEmpty, !face.triangleIndices.isEmpty else { return nil }

        let centroid = raw.reduce(SIMD3<Float>(repeating: 0), +) / Float(raw.count)
        let centered = raw.map { $0 - centroid }

        var d = MeshDescriptor(name: "face")
        d.positions = MeshBuffers.Positions(centered)
        d.primitives = .triangles(face.triangleIndices.map { UInt32($0) })
        d.materials = .allFaces(0)

        // intentionally silent: visual-only fallback — a failed mesh build just shows
        // an empty viewport; indices were validated at decode time in CapturedFace.
        guard let resource = try? MeshResource.generate(from: [d]) else { return nil }

        let colors = vertexColors(vertexCount: centered.count)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: dominantTint(colors: colors))
        material.roughness = 0.7
        material.metallic = 0.0

        let entity = ModelEntity(mesh: resource, materials: [material])
        return (entity, centroid)
    }

    private func vertexColors(vertexCount: Int) -> [SIMD4<Float>] {
        // Skin neutral baseline matches Theme.canvas-on-mesh — slightly warm grey.
        let neutral = SIMD4<Float>(0.78, 0.78, 0.80, 1)
        var colors = Array(repeating: neutral, count: vertexCount)
        for (region, severity) in regionSeverity {
            guard let indices = FaceLandmarkIndices.regionVertices[region] else { continue }
            let domain = regionDomain[region] ?? .symmetry
            let c = domain.meshTint(severity)
            for i in indices where i >= 0 && i < vertexCount { colors[i] = c }
        }
        return colors
    }

    private func dominantTint(colors: [SIMD4<Float>]) -> UIColor {
        let avg = colors.reduce(SIMD4<Float>(repeating: 0), +) / Float(max(colors.count, 1))
        return UIColor(red: CGFloat(avg.x), green: CGFloat(avg.y), blue: CGFloat(avg.z), alpha: 1)
    }
}

// MARK: - Domain-aware mesh tints

private extension FaceDomain {
    /// SIMD4 RGBA tint for the mesh, blending the domain hue with a skin-neutral
    /// baseline by severity. `.normal` returns the neutral.
    func meshTint(_ severity: MetricResult.Severity) -> SIMD4<Float> {
        let neutral = SIMD4<Float>(0.78, 0.78, 0.80, 1)
        let target  = self.hueRGB
        let mix: Float
        switch severity {
        case .normal:      mix = 0.0
        case .mild:        mix = 0.35
        case .moderate:    mix = 0.70
        case .significant: mix = 1.0
        }
        return neutral * (1 - mix) + target * mix
    }

    /// SIMD4 representation of the domain hue used for mesh shading.
    var hueRGB: SIMD4<Float> {
        switch self {
        case .skinQuality: return SIMD4(0.478, 0.502, 0.580, 1) // #7A8094 slate
        case .facialShape: return SIMD4(0.651, 0.706, 0.867, 1) // #A6B4DD periwinkle
        case .proportions: return SIMD4(0.604, 0.698, 0.839, 1) // #9AB2D6 soft blue
        case .symmetry:    return SIMD4(0.914, 0.710, 0.878, 1) // #E9B5E0 magenta-pink
        case .expression:  return SIMD4(0.788, 0.733, 0.933, 1) // #C9BBEE lavender
        }
    }
}
