import Foundation
import RealityKit
import SwiftUI
import Combine
import UIKit

/// Renders a face mesh to a `UIImage` for PDF embedding via an offscreen `ARView`.
///
/// Replaces the old SwiftUI `ImageRenderer` path, which cannot rasterize
/// `UIViewRepresentable`/Metal content — those PDF mesh slots rendered blank (masked
/// on page 1 by the frontal-photo fallback; the comparison report's slots were
/// simply empty).
///
/// RealityKit does not render detached views, so the ARView is attached to a hidden
/// off-screen `UIWindow`, given a few frames to draw (and for texture bakes to
/// land), then captured with `ARView.snapshot`.
@MainActor
enum MeshSnapshotRenderer {

    static func render(face: CapturedFace,
                       photoJPEG: Data?,
                       regionSeverity: [FacialRegion: MetricResult.Severity],
                       regionDomain: [FacialRegion: FaceDomain],
                       size: CGSize = CGSize(width: 1200, height: 800)) async -> UIImage? {
        let arView = ARView(frame: CGRect(origin: .zero, size: size),
                            cameraMode: .nonAR,
                            automaticallyConfigureSession: false)
        arView.environment.background = .color(UIColor(Theme.meshCanvas))

        let style = FaceMeshStyle(
            surface: .automatic,
            heatmap: HeatmapInput(regionSeverity: regionSeverity, regionDomain: regionDomain),
            castsShadows: true,
            generateCollision: false
        )
        let cacheKey = "capture-\(face.timestamp.timeIntervalSinceReferenceDate)"
        guard let result = FaceMeshBuilder.build(face: face, photoJPEG: photoJPEG,
                                                 style: style, cacheKey: cacheKey) else { return nil }

        let anchor = AnchorEntity(world: [0, 0, -0.4])
        anchor.addChild(result.entity)
        arView.scene.addAnchor(anchor)
        FaceMeshLighting.apply(to: arView, anchor: anchor, castsShadows: true)
        // Match the interactive viewer's default framing (FaceMeshController baseScale).
        result.entity.scale = SIMD3<Float>(repeating: 3.0)

        // Attach to a hidden window parked off-screen — required for RealityKit to
        // schedule frames at all.
        let window = makeOffscreenWindow(size: size)
        window.addSubview(arView)
        window.isHidden = false
        defer {
            arView.removeFromSuperview()
            window.isHidden = true
        }

        // Texture bakes (photo atlas / heatmap) must land before we capture.
        await result.bakeTask?.value
        // Then let the renderer draw a few frames (2 s safety timeout).
        await waitForFrames(arView, count: 3, timeout: 2)

        return await withCheckedContinuation { continuation in
            arView.snapshot(saveToHDR: false) { image in
                continuation.resume(returning: image)
            }
        }
    }

    private static func makeOffscreenWindow(size: CGSize) -> UIWindow {
        let frame = CGRect(origin: CGPoint(x: -2 * size.width, y: 0), size: size)
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = frame
        } else {
            window = UIWindow(frame: frame)
        }
        window.windowLevel = .normal - 1
        window.rootViewController = UIViewController()
        return window
    }

    /// Resolves after `count` scene updates or `timeout` seconds, whichever first —
    /// an ARView that never starts rendering must not hang the export.
    private static func waitForFrames(_ arView: ARView, count: Int, timeout: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var remaining = count
            var finished = false
            var subscription: Cancellable?
            func finish() {
                guard !finished else { return }
                finished = true
                subscription?.cancel()
                continuation.resume()
            }
            subscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
                remaining -= 1
                if remaining <= 0 { finish() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { finish() }
        }
    }
}
