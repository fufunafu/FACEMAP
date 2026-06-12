import SwiftUI
import ARKit
import CoreImage
import RealityKit
import AVFoundation
import UIKit

/// SwiftUI host for an `ARView` configured for front-camera face tracking.
/// The coordinator owns the AR session and emits `CapturedFace` snapshots.
struct FaceCaptureView: UIViewRepresentable {
    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        /// Snapshot callback: the averaged mesh plus a portrait-oriented JPEG of the
        /// camera frame at capture time (nil if the frame couldn't be encoded).
        let onSnapshot: (CapturedFace, Data?) -> Void
        let onTrackingState: (TrackingState) -> Void
        let onHeadPose: (HeadPose) -> Void

        private static let ciContext = CIContext()

        /// Buffer of recent geometries used for frame averaging on capture.
        private var recentGeometries: [(vertices: [SIMD3<Float>], transform: simd_float4x4, blendShapes: [String: Float])] = []
        private let bufferSize = 10
        private var triangleIndices: [Int16] = []
        /// Set true by `updateUIView` when a capture is requested; honored on the next frame.
        var pendingSnapshot = false

        init(onSnapshot: @escaping (CapturedFace, Data?) -> Void,
             onTrackingState: @escaping (TrackingState) -> Void,
             onHeadPose: @escaping (HeadPose) -> Void) {
            self.onSnapshot = onSnapshot
            self.onTrackingState = onTrackingState
            self.onHeadPose = onHeadPose
        }

        enum TrackingState: Equatable {
            case unsupported
            /// Camera access denied or restricted — user must change it in Settings.
            case permissionDenied
            /// The AR session reported a non-recoverable error.
            case sessionFailed
            /// The session is temporarily interrupted (phone call, backgrounding, Split View…).
            case interrupted
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
                // Keep the request alive if this frame couldn't produce a snapshot
                // (e.g. mixed-topology buffer) so a later frame can retry.
                if captureSnapshot() { pendingSnapshot = false }
            }
        }

        // MARK: ARSessionDelegate — failure & interruption

        func session(_ session: ARSession, didFailWithError error: Error) {
            clearFrameBuffer()
            if let arError = error as? ARError, arError.code == .cameraUnauthorized {
                onTrackingState(.permissionDenied)
            } else {
                onTrackingState(.sessionFailed)
            }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            clearFrameBuffer()
            onTrackingState(.interrupted)
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            // Tracking resumes via didUpdate; report a neutral state until a face is found.
            onTrackingState(.noFace)
        }

        /// Drops buffered frames and any in-flight capture request. Called on
        /// interruption/failure so a resumed session can't average stale frames.
        func clearFrameBuffer() {
            recentGeometries.removeAll()
            pendingSnapshot = false
        }

        /// Average the buffered frames into a single CapturedFace and emit it.
        /// Returns false when no valid snapshot could be produced.
        @discardableResult
        func captureSnapshot() -> Bool {
            guard !triangleIndices.isEmpty,
                  let reference = recentGeometries.last?.vertices.count,
                  reference > 0 else { return false }
            // Only average samples that share the latest frame's topology — a mid-buffer
            // vertex-count change would otherwise corrupt (or crash) the average.
            let samples = recentGeometries.filter { $0.vertices.count == reference }
            guard !samples.isEmpty else { return false }

            let count = samples.count
            let n = reference
            var avg = Array(repeating: SIMD3<Float>(repeating: 0), count: n)
            for sample in samples {
                for i in 0..<n { avg[i] += sample.vertices[i] }
            }
            let scale = Float(1) / Float(count)
            for i in 0..<n { avg[i] *= scale }

            let last = samples.last!
            let face = CapturedFace(
                vertices: avg,
                triangleIndices: triangleIndices,
                transform: last.transform,
                blendShapes: last.blendShapes,
                timestamp: Date()
            )
            onSnapshot(face, currentFramePhotoJPEG())
            return true
        }

        /// JPEG of the camera frame at capture time, rotated to portrait. The raw
        /// sensor image is unmirrored, which matches clinical-photography convention
        /// (the patient as others see them) — do not mirror it to match the preview.
        private func currentFramePhotoJPEG() -> Data? {
            guard let pixelBuffer = arView?.session.currentFrame?.capturedImage else { return nil }
            let ci = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
            guard let cg = Self.ciContext.createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: cg).jpegData(compressionQuality: 0.85)
        }
    }

    let onSnapshot: (CapturedFace, Data?) -> Void
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

        // Pre-flight camera authorization — a denied camera otherwise leaves the
        // session silently dead while the UI waits for a face forever.
        let coordinator = context.coordinator
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            Self.runFaceTrackingSession(on: view, coordinator: coordinator)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    guard let view = coordinator.arView else { return }
                    if granted {
                        Self.runFaceTrackingSession(on: view, coordinator: coordinator)
                    } else {
                        coordinator.onTrackingState(.permissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            coordinator.onTrackingState(.permissionDenied)
        @unknown default:
            coordinator.onTrackingState(.permissionDenied)
        }
        return view
    }

    private static func runFaceTrackingSession(on view: ARView, coordinator: Coordinator) {
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        if ARFaceTrackingConfiguration.supportsWorldTracking {
            config.isWorldTrackingEnabled = false
        }
        view.session.delegate = coordinator
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
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
