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
    /// Build product for the attached mesh — carries the surface/heatmap toggles
    /// used by the full-screen viewer's controls.
    internal private(set) var buildResult: FaceMeshBuildResult?

    private var yaw: Float = 0
    private var pitch: Float = 0
    private var scaleMul: Float = 1.0
    private let baseScale: Float = 3.0
    private let pitchClamp: Float = 1.4

    internal func attach(_ entity: ModelEntity) {
        self.entity = entity
        applyTransform()
    }

    internal func attach(_ result: FaceMeshBuildResult) {
        buildResult = result
        attach(result.entity)
    }

    /// Photo ↔ clay surface toggle (no-op until the photo texture bake lands).
    func setSurface(_ surface: FaceMeshStyle.Surface) {
        buildResult?.setSurface(surface)
    }

    func setHeatmapVisible(_ visible: Bool) {
        buildResult?.setHeatmapVisible(visible)
    }

    /// Whether a photo-textured surface is (or will become) available.
    var hasPhotoSurface: Bool { buildResult?.hasPhotoSurface ?? false }

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
    /// Frontal clinical photo for the photo-textured surface. Nil (or a capture
    /// without projection data) falls back to the clay surface.
    var photoJPEG: Data? = nil
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

        let style = FaceMeshStyle(
            surface: .automatic,
            heatmap: HeatmapInput(regionSeverity: regionSeverity, regionDomain: regionDomain),
            castsShadows: interactive,   // thumbnails skip the shadow map
            generateCollision: false
        )
        // Timestamp is unique per capture — a stable texture-cache key without
        // needing the owning case's identity threaded through every call site.
        let cacheKey = "capture-\(face.timestamp.timeIntervalSinceReferenceDate)"
        guard let result = FaceMeshBuilder.build(face: face, photoJPEG: photoJPEG,
                                                 style: style, cacheKey: cacheKey) else { return }

        let anchor = AnchorEntity(world: [0, 0, -0.4])
        anchor.addChild(result.entity)
        view.scene.addAnchor(anchor)

        FaceMeshLighting.apply(to: view, anchor: anchor, castsShadows: style.castsShadows)

        if !constructions.isEmpty {
            MetricConstructionRenderer.render(
                constructions, on: result.entity, centroid: result.centroid
            )
        }

        controller.attach(result)
    }
}
