import SwiftUI

/// Minimal single-pose capture used ONLY to obtain a mesh for landmark calibration.
/// Solves the gate's chicken-and-egg: clinical capture is blocked until calibration
/// is complete, but calibration itself needs a captured mesh — so this flow captures
/// one frontal mesh (the practitioner's own face is fine), pushes `CalibrationScreen`,
/// and never creates a `PatientCase`. The photo JPEG is discarded.
///
/// Deliberately separate from `CaptureScreen`, which is entangled with 3-pose
/// ordering, session resume, retakes, clinical photos, and the Analysis handoff.
struct CalibrationCaptureScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var captureRequested = false
    @State private var trackingState: FaceCaptureView.Coordinator.TrackingState = .noFace
    @State private var gateViolations: [CaptureGate.Violation] = []
    @State private var poseInWindowSince: Date?
    @State private var isCapturing = false
    @State private var autoCaptureInFlight = false
    /// The captured mesh, ready for calibration. Setting it pushes `CalibrationScreen`.
    @State private var capturedForCalibration: CapturedFace?
    @State private var navigateToCalibration = false

    private let holdDuration: TimeInterval = 0.6

    private var isPoseInWindow: Bool {
        trackingState == .tracking && gateViolations.isEmpty
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if FaceTracking.isSupportedOnThisDevice {
                FaceCaptureView(
                    onSnapshot: handleSnapshot,
                    onTrackingState: handleTrackingState,
                    onFrameState: handleFrameState,
                    targetPose: .frontal,
                    captureRequested: $captureRequested
                )
                .ignoresSafeArea()
            } else {
                unsupportedView
            }

            VStack {
                statusBanner
                Spacer()
                instructionCard
                captureButton
            }
            .padding()

            if isCapturing { capturingOverlay }
        }
        .navigationTitle("Calibration capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToCalibration) {
            if let face = capturedForCalibration {
                CalibrationScreen(face: face) {
                    // Fully calibrated → pop back; the caller's gate has already
                    // lifted via the store's ObservableObject publish. A partial
                    // save keeps this screen (and its mesh) alive to resume.
                    if LandmarkCalibrationStore.shared.isFullyCalibrated {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Session callbacks (single frontal pose, same gating as CaptureScreen)

    private func handleSnapshot(_ face: CapturedFace, photoJPEG: Data?) {
        // photoJPEG deliberately discarded — this capture never becomes a case.
        let wasAuto = autoCaptureInFlight
        autoCaptureInFlight = false
        isCapturing = false
        poseInWindowSince = nil

        if wasAuto {
            let stillClean = face.quality.map { $0.gateViolations.isEmpty } ?? gateViolations.isEmpty
            guard stillClean else { return }
        }
        capturedForCalibration = face
        navigateToCalibration = true
    }

    private func handleTrackingState(_ state: FaceCaptureView.Coordinator.TrackingState) {
        trackingState = state
        if state != .tracking {
            gateViolations = []
            poseInWindowSince = nil
            isCapturing = false
            autoCaptureInFlight = false
        }
    }

    private func handleFrameState(_ pose: HeadPose, _ violations: [CaptureGate.Violation]) {
        gateViolations = violations
        if violations.isEmpty {
            if poseInWindowSince == nil { poseInWindowSince = Date() }
            if !isCapturing, let since = poseInWindowSince,
               Date().timeIntervalSince(since) >= holdDuration {
                triggerCapture(auto: true)
            }
        } else {
            poseInWindowSince = nil
        }
    }

    private func triggerCapture(auto: Bool = false) {
        guard trackingState == .tracking, !isCapturing else { return }
        isCapturing = true
        autoCaptureInFlight = auto
        captureRequested = true
    }

    // MARK: - UI

    private var statusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPoseInWindow ? Theme.ink : Theme.inkDim)
                .frame(width: 8, height: 8)
            Text(bannerText)
                .font(Type.callout)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .padding(.top, 16)
    }

    private var bannerText: String {
        switch trackingState {
        case .unsupported:      return "TrueDepth not available on this device"
        case .permissionDenied: return "Camera access is off"
        case .sessionFailed:    return "Camera session failed"
        case .interrupted:      return "Camera paused"
        case .noFace:           return "Position a face in front of the camera"
        case .tracking:
            if isPoseInWindow { return "Hold — capturing…" }
            return gateViolations.first?.coachingText ?? "Face detected"
        }
    }

    private var instructionCard: some View {
        VStack(spacing: 6) {
            Text("Capture one frontal mesh to calibrate on")
                .font(Type.body.weight(.medium))
                .foregroundStyle(Theme.ink)
            Text("Your own face is fine — this capture is used only for calibration and is never saved as a patient case.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
        .padding(.bottom, 8)
    }

    private var captureButton: some View {
        VStack(spacing: 8) {
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let progress: Double = {
                        guard let since = poseInWindowSince else { return 0 }
                        return min(context.date.timeIntervalSince(since) / holdDuration, 1.0)
                    }()
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 96, height: 96)
                }
                Button(action: { triggerCapture() }) {
                    Circle().fill(Theme.ink).frame(width: 78, height: 78)
                }
                .disabled(trackingState != .tracking || isCapturing)
                .opacity(trackingState == .tracking && !isCapturing ? 1 : 0.4)
                .accessibilityLabel("Capture calibration mesh")
            }
        }
        .padding(.bottom, 8)
    }

    private var capturingOverlay: some View {
        ZStack {
            Theme.canvas.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().scaleEffect(1.4).tint(Theme.ink)
                Text("Capturing…")
                    .font(Type.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 48))
                .foregroundStyle(Theme.inkDim)
            Text("This device does not support face tracking.")
                .font(Type.body)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
