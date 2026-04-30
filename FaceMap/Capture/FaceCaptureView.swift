import SwiftUI
import ARKit
import RealityKit

/// SwiftUI host for an `ARView` configured for front-camera face tracking.
/// The coordinator owns the AR session and emits `CapturedFace` snapshots.
struct FaceCaptureView: UIViewRepresentable {
    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        let onSnapshot: (CapturedFace) -> Void
        let onTrackingState: (TrackingState) -> Void
        let onHeadPose: (HeadPose) -> Void

        /// Buffer of recent geometries used for frame averaging on capture.
        private var recentGeometries: [(vertices: [SIMD3<Float>], transform: simd_float4x4, blendShapes: [String: Float])] = []
        private let bufferSize = 10
        private var triangleIndices: [Int16] = []
        /// Set true by `updateUIView` when a capture is requested; honored on the next frame.
        var pendingSnapshot = false

        init(onSnapshot: @escaping (CapturedFace) -> Void,
             onTrackingState: @escaping (TrackingState) -> Void,
             onHeadPose: @escaping (HeadPose) -> Void) {
            self.onSnapshot = onSnapshot
            self.onTrackingState = onTrackingState
            self.onHeadPose = onHeadPose
        }

        enum TrackingState: Equatable {
            case unsupported
            case noFace
            case tracking
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let face = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                onTrackingState(.noFace)
                return
            }
            onTrackingState(.tracking)
            onHeadPose(HeadPose.from(transform: face.transform))
            let geom = face.geometry
            if triangleIndices.isEmpty {
                triangleIndices = geom.triangleIndices.map { Int16($0) }
            }
            let blendDict: [String: Float] = Dictionary(
                uniqueKeysWithValues: face.blendShapes.map { ($0.key.rawValue, $0.value.floatValue) }
            )
            recentGeometries.append((geom.vertices, face.transform, blendDict))
            if recentGeometries.count > bufferSize { recentGeometries.removeFirst() }

            if pendingSnapshot, recentGeometries.count >= bufferSize {
                pendingSnapshot = false
                captureSnapshot()
            }
        }

        /// Average the buffered frames into a single CapturedFace and emit it.
        func captureSnapshot() {
            guard !recentGeometries.isEmpty, !triangleIndices.isEmpty else { return }
            let count = recentGeometries.count
            let n = recentGeometries[0].vertices.count
            var avg = Array(repeating: SIMD3<Float>(repeating: 0), count: n)
            for sample in recentGeometries {
                for i in 0..<n { avg[i] += sample.vertices[i] }
            }
            let scale = Float(1) / Float(count)
            for i in 0..<n { avg[i] *= scale }

            let last = recentGeometries.last!
            let face = CapturedFace(
                vertices: avg,
                triangleIndices: triangleIndices,
                transform: last.transform,
                blendShapes: last.blendShapes,
                timestamp: Date()
            )
            onSnapshot(face)
        }
    }

    let onSnapshot: (CapturedFace) -> Void
    let onTrackingState: (Coordinator.TrackingState) -> Void
    var onHeadPose: (HeadPose) -> Void = { _ in }
    @Binding var captureRequested: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSnapshot: onSnapshot,
            onTrackingState: onTrackingState,
            onHeadPose: onHeadPose
        )
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = view

        guard ARFaceTrackingConfiguration.isSupported else {
            context.coordinator.onTrackingState(.unsupported)
            return view
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        if ARFaceTrackingConfiguration.supportsWorldTracking {
            config.isWorldTrackingEnabled = false
        }
        view.session.delegate = context.coordinator
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if captureRequested {
            context.coordinator.pendingSnapshot = true
            DispatchQueue.main.async { captureRequested = false }
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }
}
