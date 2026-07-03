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
        /// Snapshot callback: the aggregated mesh plus a portrait-oriented JPEG of the
        /// camera frame at capture time (nil if the frame couldn't be encoded).
        let onSnapshot: (CapturedFace, Data?) -> Void
        let onTrackingState: (TrackingState) -> Void
        /// Per-frame head pose + active capture-gate violations (empty = ready).
        let onFrameState: (HeadPose, [CaptureGate.Violation]) -> Void

        private static let ciContext = CIContext()

        /// Buffer of recent geometries used for frame aggregation on capture.
        private var recentGeometries: [(vertices: [SIMD3<Float>], transform: simd_float4x4,
                                        blendShapes: [String: Float], headPose: HeadPose)] = []
        private let bufferSize = 10
        private var triangleIndices: [Int16] = []
        /// Set true by `updateUIView` when a capture is requested; honored on the next frame.
        var pendingSnapshot = false
        /// The pose the coached flow is currently capturing — drives gate evaluation
        /// and the quality score's yaw-error term. Mirrored from SwiftUI by `updateUIView`.
        var targetPose: CapturePose = .frontal

        init(onSnapshot: @escaping (CapturedFace, Data?) -> Void,
             onTrackingState: @escaping (TrackingState) -> Void,
             onFrameState: @escaping (HeadPose, [CaptureGate.Violation]) -> Void) {
            self.onSnapshot = onSnapshot
            self.onTrackingState = onTrackingState
            self.onFrameState = onFrameState
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
            let headPose = HeadPose.from(transform: face.transform)
            let blendDict: [String: Float] = Dictionary(
                uniqueKeysWithValues: face.blendShapes.map { ($0.key.rawValue, $0.value.floatValue) }
            )
            onFrameState(headPose, CaptureGate.evaluate(targetPose: targetPose,
                                                        pose: headPose,
                                                        blendShapes: blendDict))
            let geom = face.geometry
            if triangleIndices.isEmpty {
                triangleIndices = geom.triangleIndices.map { Int16($0) }
            }
            recentGeometries.append((geom.vertices, face.transform, blendDict, headPose))
            if recentGeometries.count > bufferSize { recentGeometries.removeFirst() }

            if pendingSnapshot, recentGeometries.count >= bufferSize {
                // Keep the request alive if this frame couldn't produce a snapshot
                // (e.g. mixed-topology buffer) so a later frame can retry.
                if captureSnapshot(frame: frame, faceAnchor: face) { pendingSnapshot = false }
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

        /// Aggregate the buffered frames into a single CapturedFace and emit it,
        /// together with a JPEG of the trigger frame. Everything photo-related
        /// (pixels, intrinsics, camera transform, face transform) comes from the ONE
        /// `frame`/`faceAnchor` pair passed in — the frame that triggered the
        /// snapshot — so the texture-projection data is self-consistent. (The old
        /// implementation pulled the JPEG from `session.currentFrame`, which could
        /// already be a different frame.)
        /// Returns false when no valid snapshot could be produced.
        @discardableResult
        func captureSnapshot(frame: ARFrame, faceAnchor: ARFaceAnchor) -> Bool {
            guard !triangleIndices.isEmpty,
                  let reference = recentGeometries.last?.vertices.count,
                  reference > 0 else { return false }
            // Only aggregate samples that share the latest frame's topology — a mid-buffer
            // vertex-count change would otherwise corrupt (or crash) the result.
            let samples = recentGeometries.filter { $0.vertices.count == reference }
            guard !samples.isEmpty else { return false }

            let vertexSamples = samples.map { $0.vertices }
            let aggregated = FrameAggregator.robustAverage(vertexSamples)
            let (meanJitterMM, maxJitterMM) = FrameAggregator.jitterStats(vertexSamples)
            // Transform + blendshapes must stay a coherent single-frame snapshot;
            // take them from the medoid — the buffered frame closest to the
            // aggregated mesh — rather than blindly from the last frame.
            let medoid = samples[FrameAggregator.medoidIndex(of: vertexSamples, against: aggregated)]

            // Photo-frame state for texture projection and the quality score.
            let photoHeadPose = HeadPose.from(transform: faceAnchor.transform)
            let blendDict: [String: Float] = Dictionary(
                uniqueKeysWithValues: faceAnchor.blendShapes.map { ($0.key.rawValue, $0.value.floatValue) }
            )
            let violations = CaptureGate.evaluate(targetPose: targetPose,
                                                  pose: photoHeadPose,
                                                  blendShapes: blendDict)
            let quality = CaptureQuality.compute(
                framesAveraged: samples.count,
                meanJitterMM: meanJitterMM,
                maxJitterMM: maxJitterMM,
                yawErrorDegrees: Float(targetPose.yawError(currentDegrees: photoHeadPose.yawDegrees)),
                pitchDegrees: Float(photoHeadPose.pitchDegrees),
                rollDegrees: Float(photoHeadPose.rollDegrees),
                expressionMax: CaptureGate.expressionRatio(blendShapes: blendDict),
                gateViolations: violations.map(\.rawValue)
            )

            // Canonical UVs are read per capture (not cached like triangleIndices):
            // ~10 KB once per snapshot, and a per-capture read stays trivially correct
            // if the topology ever changes between sessions.
            let uvs = faceAnchor.geometry.textureCoordinates.map { SIMD2(Float($0.x), Float($0.y)) }
            let resolution = frame.camera.imageResolution

            let face = CapturedFace(
                vertices: aggregated,
                triangleIndices: triangleIndices,
                transform: medoid.transform,
                blendShapes: medoid.blendShapes,
                timestamp: Date(),
                textureCoordinates: uvs,
                cameraIntrinsics: frame.camera.intrinsics,
                cameraImageResolution: SIMD2(Float(resolution.width), Float(resolution.height)),
                cameraTransform: frame.camera.transform,
                photoFaceTransform: faceAnchor.transform,
                quality: quality
            )
            onSnapshot(face, photoJPEG(from: frame))
            return true
        }

        /// JPEG of the trigger frame, rotated to portrait. The raw sensor image is
        /// unmirrored, which matches clinical-photography convention (the patient as
        /// others see them) — do not mirror it to match the preview.
        /// Resolution is deliberately left at the AR video format's native size: the
        /// face spans only a few hundred pixels of the frame and the photo doubles as
        /// the mesh texture. (Future option: pick the largest
        /// `ARFaceTrackingConfiguration.supportedVideoFormats` entry for more texels.)
        private func photoJPEG(from frame: ARFrame) -> Data? {
            let ci = CIImage(cvPixelBuffer: frame.capturedImage).oriented(.right)
            guard let cg = Self.ciContext.createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: cg).jpegData(compressionQuality: 0.85)
        }
    }

    let onSnapshot: (CapturedFace, Data?) -> Void
    let onTrackingState: (Coordinator.TrackingState) -> Void
    var onFrameState: (HeadPose, [CaptureGate.Violation]) -> Void = { _, _ in }
    /// The pose the coached flow is currently capturing (gates + quality scoring).
    var targetPose: CapturePose = .frontal
    @Binding var captureRequested: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSnapshot: onSnapshot,
            onTrackingState: onTrackingState,
            onFrameState: onFrameState
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
        context.coordinator.targetPose = targetPose
        if captureRequested {
            context.coordinator.pendingSnapshot = true
            DispatchQueue.main.async { captureRequested = false }
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }
}
