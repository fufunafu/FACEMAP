import SwiftUI
import ARKit

/// Coached three-pose capture: frontal → oblique-L (patient's left side visible) →
/// oblique-R. Each pose has a target yaw (±5°). When the patient holds the right
/// pose for `holdDuration` seconds, the screen auto-snapshots. The user can also
/// tap the capture button to force a snapshot at any time. After all three are
/// captured, the analysis screen opens with the full `MultiPoseCapture`.
struct CaptureScreen: View {
    @EnvironmentObject var store: CaseStore
    @Environment(\.scenePhase) private var scenePhase

    /// Patient this capture session belongs to. Threaded through to `AnalysisScreen`
    /// so the save sheet pre-fills and locks the patient instead of dumping the case
    /// into the Unassigned bucket. Nil for ad-hoc captures from the Capture tab.
    var patient: Patient? = nil

    // AR session state
    @State private var captureRequested = false
    @State private var trackingState: FaceCaptureView.Coordinator.TrackingState = .noFace
    @State private var headPose: HeadPose?
    /// Capture-gate violations for the current frame (pose window, level-ness,
    /// neutral expression). Auto-capture requires this to stay empty for the full
    /// hold duration; the first entry drives the coaching copy.
    @State private var gateViolations: [CaptureGate.Violation] = []
    @State private var isCapturing = false
    /// True while a snapshot triggered by the auto hold-to-capture path is in flight,
    /// so the result can be re-verified against the yaw window when it lands.
    @State private var autoCaptureInFlight = false

    // Multi-pose flow state
    @State private var currentPose: CapturePose = .frontal
    @State private var captures: [CapturePose: CapturedFace] = [:]
    @State private var photos: [CapturePose: Data] = [:]
    @State private var poseInWindowSince: Date?
    @State private var multiPoseResult: MultiPoseCapture?
    @State private var navigateToAnalysis = false
    /// Set by AnalysisScreen's onSaved callback; gates the onAppear session reset.
    @State private var sessionSaved = false

    /// Auto-capture fires after the pose has been held in-window for this long.
    private let holdDuration: TimeInterval = 0.6

    /// Sequence order for the coached flow.
    private let poseOrder: [CapturePose] = [.frontal, .obliqueL, .obliqueR]

    private var isPoseInWindow: Bool {
        guard headPose != nil, trackingState == .tracking else { return false }
        return gateViolations.isEmpty
    }

    /// States where the camera feed is unusable and the user needs an explanation.
    private var sessionHasIssue: Bool {
        switch trackingState {
        case .permissionDenied, .sessionFailed, .interrupted: return true
        case .unsupported, .noFace, .tracking:                return false
        }
    }

    // TODO: migrate to Theme.warning token
    private let warningAmber = Color(hex: 0xC77D0A)

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if FaceTracking.isSupportedOnThisDevice {
                FaceCaptureView(
                    onSnapshot: handleSnapshot,
                    onTrackingState: handleTrackingState,
                    onFrameState: handleFrameState,
                    targetPose: currentPose,
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
                if !captures.isEmpty {
                    startOverButton
                }
                Spacer()
                if sessionHasIssue {
                    sessionIssueCard
                } else {
                    instructions
                }
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
                AnalysisScreen(multiPose: multi, patient: patient) {
                    sessionSaved = true
                }
            }
        }
        .onAppear {
            // The NavigationStack keeps this view alive after a completed session.
            // Reset only once the session was actually SAVED — a plain back-swipe
            // from an unsaved AnalysisScreen must not destroy three captured poses.
            // The unsaved session stays resumable (and restartable via Start over),
            // and a fresh visit can never inherit poses from a saved one.
            if sessionSaved {
                resetSession()
                sessionSaved = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                poseInWindowSince = nil
                isCapturing = false
                autoCaptureInFlight = false
                captureRequested = false
            }
        }
    }

    // MARK: - Session callbacks

    private func handleSnapshot(_ face: CapturedFace, photoJPEG: Data?) {
        let wasAuto = autoCaptureInFlight
        autoCaptureInFlight = false
        isCapturing = false
        poseInWindowSince = nil

        if wasAuto {
            // Re-verify at snapshot time — the head may have left the window (or the
            // expression changed) between the trigger and the frame-buffered snapshot
            // landing. The snapshot's own recorded gate state is race-free; the yaw
            // re-check is the fallback for captures without a quality record.
            let stillClean = face.quality.map { $0.gateViolations.isEmpty }
                ?? headPose.map { currentPose.contains(yawDegrees: $0.yawDegrees) }
                ?? false
            guard stillClean else { return }
        }

        captures[currentPose] = face
        photos[currentPose] = photoJPEG
        advanceOrFinish()
    }

    /// Moves to the first uncaptured pose, or finalizes the multi-pose capture.
    /// "First uncaptured" (not "next in order") so per-pose retakes rejoin the flow.
    private func advanceOrFinish() {
        if let next = poseOrder.first(where: { captures[$0] == nil }) {
            currentPose = next
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

    /// Clears every piece of per-session state. A stale `captures` dictionary would
    /// otherwise mix poses from two different visits into one snapshot.
    private func resetSession() {
        captures.removeAll()
        photos.removeAll()
        currentPose = .frontal
        poseInWindowSince = nil
        isCapturing = false
        autoCaptureInFlight = false
        captureRequested = false
        multiPoseResult = nil
    }

    /// Discards a single completed pose and rejoins the coached flow at that pose.
    private func retake(_ pose: CapturePose) {
        guard captures[pose] != nil, !isCapturing else { return }
        captures[pose] = nil
        photos[pose] = nil
        currentPose = pose
        poseInWindowSince = nil
    }

    private func handleTrackingState(_ state: FaceCaptureView.Coordinator.TrackingState) {
        trackingState = state
        if state != .tracking {
            headPose = nil
            gateViolations = []
            poseInWindowSince = nil
            isCapturing = false
            autoCaptureInFlight = false
        }
    }

    private func handleFrameState(_ pose: HeadPose, _ violations: [CaptureGate.Violation]) {
        headPose = pose
        gateViolations = violations
        if violations.isEmpty {
            // Any violation resets the hold timer, so a gate must pass continuously
            // for the full hold — this debounces blendshape flicker for free.
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

    // MARK: - Top: progress bar (tap a completed segment to retake that pose)

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(poseOrder) { pose in
                let captured = captures[pose] != nil
                let current = pose == currentPose && !captured
                Button {
                    retake(pose)
                } label: {
                    Capsule()
                        .fill(captured ? Theme.ink : (current ? Theme.inkMuted : Theme.inkMuted.opacity(0.3)))
                        .frame(height: 4)
                        .overlay(alignment: .center) {
                            Text(pose.label)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(captured || current ? Theme.canvas : Theme.inkMuted)
                                .offset(y: 14)
                        }
                        // Inset outward so the 4-pt capsule has a tappable retake target.
                        .contentShape(Rectangle().inset(by: -14))
                }
                .buttonStyle(.plain)
                .disabled(!captured)
                .accessibilityLabel(captured ? "Retake \(pose.displayName)" : pose.displayName)
            }
        }
        .padding(.top, 8)
    }

    private var startOverButton: some View {
        HStack(spacing: 8) {
            Button {
                resetSession()
            } label: {
                Label("Start over", systemImage: "arrow.counterclockwise")
                    .font(Type.captionStrong)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Start over — discard captured poses")

            // An unsaved completed session (user backed out of Analysis) can be
            // re-entered without recapturing all three poses.
            if multiPoseResult != nil, !navigateToAnalysis {
                Button {
                    navigateToAnalysis = true
                } label: {
                    Label("Resume analysis", systemImage: "arrow.right.circle")
                        .font(Type.captionStrong)
                        .foregroundStyle(Theme.canvas)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.ink, in: Capsule())
                }
                .accessibilityLabel("Resume analysis of the captured session")
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
        case .unsupported, .permissionDenied, .sessionFailed, .interrupted:
            return warningAmber
        case .noFace:   return Theme.inkDim
        case .tracking: return isPoseInWindow ? Theme.ink : Theme.inkDim
        }
    }

    private var badgeText: String {
        switch trackingState {
        case .unsupported:      return "TrueDepth not available on this device"
        case .permissionDenied: return "Camera access is off"
        case .sessionFailed:    return "Camera session failed"
        case .interrupted:      return "Camera paused"
        case .noFace:           return "Position your face in front of the camera"
        case .tracking:
            if isPoseInWindow { return "Hold — capturing…" }
            switch gateViolations.first {
            case .yawOutOfWindow:
                if let pose = headPose {
                    return String(format: "Yaw %+.0f°", pose.yawDegrees)
                }
                return CaptureGate.Violation.yawOutOfWindow.coachingText
            case .some(let violation):
                return violation.coachingText
            case .none:
                return "Face detected"
            }
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
        case .tracking: return isPoseInWindow ? Theme.ink : Theme.ink.opacity(0.55)
        case .noFace:   return Theme.ink.opacity(0.45)
        case .unsupported, .permissionDenied, .sessionFailed, .interrupted:
            return .clear
        }
    }

    // MARK: - Session-issue card (permission denied / failed / interrupted)

    private var sessionIssueCard: some View {
        VStack(spacing: 10) {
            Image(systemName: sessionIssueIcon)
                .font(.system(size: 28))
                .foregroundStyle(warningAmber)
            Text(sessionIssueHeadline)
                .font(Type.body.weight(.medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(sessionIssueDetail)
                .font(Type.caption)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
            if trackingState == .permissionDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                }
                .buttonStyle(.primary)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
        .padding(.bottom, 8)
    }

    private var sessionIssueIcon: String {
        switch trackingState {
        case .permissionDenied: return "video.slash"
        case .sessionFailed:    return "exclamationmark.triangle"
        default:                return "pause.circle"
        }
    }

    private var sessionIssueHeadline: String {
        switch trackingState {
        case .permissionDenied: return "Camera access is off"
        case .sessionFailed:    return "The camera session failed"
        default:                return "Camera paused"
        }
    }

    private var sessionIssueDetail: String {
        switch trackingState {
        case .permissionDenied:
            return "FaceMap needs the front TrueDepth camera to capture a face. Allow camera access in Settings, then return here."
        case .sessionFailed:
            return "Leave this screen and try again. If it keeps happening, restart the app."
        default:
            return "Capture will resume when the camera is available again."
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
        case .unsupported, .permissionDenied, .sessionFailed, .interrupted:
            return ""
        case .noFace:   return "Position your face in the frame"
        case .tracking:
            if isPoseInWindow { return "Hold still…" }
            // Only prompt a head turn when yaw is actually the problem; a level-ness
            // or expression violation with correct yaw should not tell the patient
            // to keep turning.
            switch gateViolations.first {
            case .yawOutOfWindow, .none: return currentPose.coachPrompt
            case .pitchTilted, .rollTilted: return "Keep the head level"
            case .jawOpen, .smiling, .browRaised, .eyesClosed: return "Neutral expression"
            }
        }
    }

    private var subhead: String {
        switch trackingState {
        case .unsupported, .permissionDenied, .sessionFailed, .interrupted:
            return ""
        case .noFace:   return "Hold the phone about an arm's length away at eye level."
        case .tracking:
            if isPoseInWindow {
                return "Capturing in under a second."
            }
            switch gateViolations.first {
            case .yawOutOfWindow, .none:
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
            case .some(let violation):
                return violation.coachingText
            }
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

                Button(action: { triggerCapture() }) {
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
        .opacity(sessionHasIssue ? 0 : 1)
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
