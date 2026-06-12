import SwiftUI
import ARKit

/// Coached three-pose capture: frontal → oblique-L (patient's left side visible) →
/// oblique-R. Each pose has a target yaw (±5°). When the patient holds the right
/// pose for `holdDuration` seconds, the screen auto-snapshots. The user can also
/// tap the capture button to force a snapshot at any time. After all three are
/// captured, the analysis screen opens with the full `MultiPoseCapture`.
struct CaptureScreen: View {
    @EnvironmentObject var store: CaseStore

    // AR session state
    @State private var captureRequested = false
    @State private var trackingState: FaceCaptureView.Coordinator.TrackingState = .noFace
    @State private var headPose: HeadPose?
    @State private var isCapturing = false

    // Multi-pose flow state
    @State private var currentPose: CapturePose = .frontal
    @State private var captures: [CapturePose: CapturedFace] = [:]
    @State private var photos: [CapturePose: Data] = [:]
    @State private var poseInWindowSince: Date?
    @State private var multiPoseResult: MultiPoseCapture?
    @State private var navigateToAnalysis = false

    /// Auto-capture fires after the pose has been held in-window for this long.
    private let holdDuration: TimeInterval = 0.6

    /// Sequence order for the coached flow.
    private let poseOrder: [CapturePose] = [.frontal, .obliqueL, .obliqueR]

    private var isPoseInWindow: Bool {
        guard let pose = headPose, trackingState == .tracking else { return false }
        return currentPose.contains(yawDegrees: pose.yawDegrees)
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if FaceTracking.isSupportedOnThisDevice {
                FaceCaptureView(
                    onSnapshot: handleSnapshot,
                    onTrackingState: handleTrackingState,
                    onHeadPose: handleHeadPose,
                    captureRequested: $captureRequested
                )
                .ignoresSafeArea()
            } else {
                unsupportedView
            }

            framingOverlay

            VStack {
                progressBar
                statusBanner
                Spacer()
                instructions
                captureControls
            }
            .padding()

            if isCapturing { capturingOverlay }
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let multi = multiPoseResult {
                AnalysisScreen(multiPose: multi)
            }
        }
    }

    // MARK: - Session callbacks

    private func handleSnapshot(_ face: CapturedFace, photoJPEG: Data?) {
        captures[currentPose] = face
        photos[currentPose] = photoJPEG
        isCapturing = false
        poseInWindowSince = nil

        if let nextIdx = poseOrder.firstIndex(of: currentPose).map({ $0 + 1 }),
           nextIdx < poseOrder.count {
            currentPose = poseOrder[nextIdx]
        } else if let frontal = captures[.frontal] {
            multiPoseResult = MultiPoseCapture(
                frontal: frontal,
                obliqueL: captures[.obliqueL],
                obliqueR: captures[.obliqueR],
                photos: photos
            )
            navigateToAnalysis = true
        }
    }

    private func handleTrackingState(_ state: FaceCaptureView.Coordinator.TrackingState) {
        trackingState = state
        if state != .tracking {
            headPose = nil
            poseInWindowSince = nil
        }
    }

    private func handleHeadPose(_ pose: HeadPose) {
        headPose = pose
        if currentPose.contains(yawDegrees: pose.yawDegrees) {
            if poseInWindowSince == nil { poseInWindowSince = Date() }
            if !isCapturing, let since = poseInWindowSince,
               Date().timeIntervalSince(since) >= holdDuration {
                triggerCapture()
            }
        } else {
            poseInWindowSince = nil
        }
    }

    private func triggerCapture() {
        guard trackingState == .tracking, !isCapturing else { return }
        isCapturing = true
        captureRequested = true
    }

    // MARK: - Top: progress bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(poseOrder) { pose in
                let captured = captures[pose] != nil
                let current = pose == currentPose && !captured
                Capsule()
                    .fill(captured ? Theme.ink : (current ? Theme.domainSymmetry.opacity(0.85) : Theme.inkMuted.opacity(0.3)))
                    .frame(height: 4)
                    .overlay(alignment: .center) {
                        Text(pose.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(captured || current ? Theme.canvas : Theme.inkMuted)
                            .offset(y: 14)
                    }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 8) {
            Circle().fill(badgeColor).frame(width: 8, height: 8)
            Text(badgeText)
                .font(Type.callout)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .padding(.top, 16)
    }

    private var badgeColor: Color {
        switch trackingState {
        case .unsupported: return Theme.domainSymmetry
        case .noFace:      return Theme.inkDim
        case .tracking:    return isPoseInWindow ? Theme.ink : Theme.inkDim
        }
    }

    private var badgeText: String {
        switch trackingState {
        case .unsupported: return "TrueDepth not available on this device"
        case .noFace:      return "Position your face in front of the camera"
        case .tracking:
            if isPoseInWindow { return "Hold — capturing…" }
            if let pose = headPose {
                let signed = currentPose.yawError(currentDegrees: pose.yawDegrees)
                if abs(signed) > currentPose.yawToleranceDegrees {
                    return String(format: "Yaw %+.0f°", pose.yawDegrees)
                }
            }
            return "Face detected"
        }
    }

    // MARK: - Framing oval

    private var framingOverlay: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height) * 0.75
            let h = w * 1.25
            let x = (geo.size.width - w) / 2
            let y = (geo.size.height - h) / 2 - 40

            RoundedRectangle(cornerRadius: w * 0.45)
                .stroke(borderColor, style: StrokeStyle(lineWidth: 2,
                                                       dash: trackingState == .tracking ? [] : [6, 6]))
                .frame(width: w, height: h)
                .position(x: x + w / 2, y: y + h / 2)
                .animation(.easeInOut(duration: 0.2), value: isPoseInWindow)
                .animation(.easeInOut(duration: 0.25), value: trackingState)
        }
        .allowsHitTesting(false)
    }

    private var borderColor: Color {
        switch trackingState {
        case .tracking:    return isPoseInWindow ? Theme.ink : Theme.ink.opacity(0.55)
        case .noFace:      return Theme.ink.opacity(0.45)
        case .unsupported: return .clear
        }
    }

    // MARK: - Instruction card

    private var instructions: some View {
        VStack(spacing: 6) {
            Text(headline)
                .font(Type.body.weight(.medium))
                .foregroundStyle(Theme.ink)
            Text(subhead)
                .font(Type.caption)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
        .padding(.bottom, 8)
        .opacity(trackingState == .unsupported ? 0 : 1)
    }

    private var headline: String {
        switch trackingState {
        case .unsupported: return ""
        case .noFace:      return "Position your face in the frame"
        case .tracking:    return isPoseInWindow ? "Hold still…" : currentPose.coachPrompt
        }
    }

    private var subhead: String {
        switch trackingState {
        case .unsupported: return ""
        case .noFace:      return "Hold the phone about an arm's length away at eye level."
        case .tracking:
            if isPoseInWindow {
                return "Capturing in under a second."
            }
            if let pose = headPose {
                let err = currentPose.yawError(currentDegrees: pose.yawDegrees)
                let direction = err > 0 ? "right" : "left"
                if abs(err) > currentPose.yawToleranceDegrees * 2 {
                    return String(format: "Target %.0f° · turn slowly to your %@",
                                  currentPose.targetYawDegrees, direction)
                }
                return String(format: "Almost there — %+.0f°", err)
            }
            return "Target yaw \(Int(currentPose.targetYawDegrees))°"
        }
    }

    // MARK: - Capture button + auto-fire ring

    private var captureControls: some View {
        VStack(spacing: 8) {
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
                    let progress: Double = {
                        guard let since = poseInWindowSince else { return 0 }
                        let elapsed = context.date.timeIntervalSince(since)
                        return min(elapsed / holdDuration, 1.0)
                    }()
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 96, height: 96)
                }

                Button(action: triggerCapture) {
                    Circle().fill(Theme.ink).frame(width: 78, height: 78)
                }
                .disabled(trackingState != .tracking || isCapturing)
                .opacity(trackingState == .tracking && !isCapturing ? 1 : 0.4)
                .accessibilityLabel("Capture \(currentPose.displayName)")
            }

            Text(buttonLabel)
                .font(Type.caption)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.regularMaterial, in: Capsule())
        }
        .padding(.bottom, 8)
    }

    private var buttonLabel: String {
        if isCapturing { return "Capturing \(currentPose.displayName)…" }
        if trackingState == .tracking {
            return isPoseInWindow ? "Hold…" : "Tap to capture \(currentPose.displayName)"
        }
        return "Waiting for face…"
    }

    // MARK: - "Capturing…" overlay

    private var capturingOverlay: some View {
        ZStack {
            Theme.canvas.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().scaleEffect(1.4).tint(Theme.ink)
                Text("Capturing \(currentPose.displayName)…")
                    .font(Type.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    // MARK: - Unsupported

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 48))
                .foregroundStyle(Theme.inkDim)
            Text("This device does not support face tracking.")
                .font(Type.body)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("FaceMap requires a TrueDepth camera (iPhone X or newer, or recent iPad Pro).")
                .font(Type.callout)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
