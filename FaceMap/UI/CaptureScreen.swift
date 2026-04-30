import SwiftUI
import ARKit

struct CaptureScreen: View {
    @EnvironmentObject var store: CaseStore
    @State private var captureRequested = false
    @State private var trackingState: FaceCaptureView.Coordinator.TrackingState = .noFace
    @State private var capturedFace: CapturedFace?
    @State private var navigateToAnalysis = false
    @State private var isCapturing = false
    @State private var headPose: HeadPose?
    /// Tolerance in degrees: any axis above this triggers the "head not level" warning.
    private let poseTolerance: Double = 5

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if FaceTracking.isSupportedOnThisDevice {
                FaceCaptureView(
                    onSnapshot: { face in
                        capturedFace = face
                        isCapturing = false
                        navigateToAnalysis = true
                    },
                    onTrackingState: { state in
                        trackingState = state
                        if state != .tracking { headPose = nil }
                    },
                    onHeadPose: { pose in headPose = pose },
                    captureRequested: $captureRequested
                )
                .ignoresSafeArea()
            } else {
                unsupportedView
            }

            framingOverlay

            VStack {
                statusBanner
                Spacer()
                instructions
                captureControls
            }
            .padding()

            if isCapturing {
                capturingOverlay
            }
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let face = capturedFace {
                AnalysisScreen(face: face)
            }
        }
    }

    // MARK: - Status banner (top)

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
        .padding(.top, 4)
    }

    private var badgeColor: Color {
        switch trackingState {
        case .unsupported: return Theme.domainSymmetry
        case .noFace:      return Theme.inkDim
        case .tracking:    return Theme.ink
        }
    }

    private var badgeText: String {
        switch trackingState {
        case .unsupported: return "TrueDepth not available on this device"
        case .noFace:      return "Position your face in front of the camera"
        case .tracking:    return "Face detected"
        }
    }

    // MARK: - Framing guide (middle)

    private var framingOverlay: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height) * 0.75
            let h = w * 1.25
            let x = (geo.size.width - w) / 2
            let y = (geo.size.height - h) / 2 - 40

            ZStack {
                RoundedRectangle(cornerRadius: w * 0.45)
                    .stroke(borderColor, style: StrokeStyle(lineWidth: 2, dash: trackingState == .tracking ? [] : [6, 6]))
                    .frame(width: w, height: h)
                    .position(x: x + w / 2, y: y + h / 2)
                    .animation(.easeInOut(duration: 0.25), value: trackingState)
            }
        }
        .allowsHitTesting(false)
    }

    private var borderColor: Color {
        switch trackingState {
        case .tracking:
            if let p = headPose, !p.isLevel(within: poseTolerance) {
                return Theme.domainSymmetry            // off-level → magenta-pink warning
            }
            return Theme.ink.opacity(0.9)
        case .noFace:      return Theme.ink.opacity(0.45)
        case .unsupported: return .clear
        }
    }

    private var poseIsOff: Bool {
        guard trackingState == .tracking, let p = headPose else { return false }
        return !p.isLevel(within: poseTolerance)
    }

    // MARK: - Instructions (above capture button)

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
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.bottom, 8)
        .opacity(trackingState == .unsupported ? 0 : 1)
    }

    private var headline: String {
        if poseIsOff { return "Keep your head level" }
        return trackingState == .tracking
            ? "Hold still — tap to capture"
            : "Center your face in the frame"
    }

    private var subhead: String {
        if poseIsOff, let pose = headPose, let detail = pose.worstAxisDescription {
            return "\(detail). A tilted pose makes apparent asymmetry. Re-centre and try again."
        }
        switch trackingState {
        case .tracking:
            return "Keep your head level and your expression neutral. Capture takes less than a second."
        case .noFace:
            return "Hold the phone about an arm's length away at eye level."
        case .unsupported:
            return ""
        }
    }

    // MARK: - Capture button

    private var captureControls: some View {
        VStack(spacing: 8) {
            Button {
                guard trackingState == .tracking else { return }
                isCapturing = true
                captureRequested = true
            } label: {
                ZStack {
                    Circle().fill(Theme.ink).frame(width: 78, height: 78)
                    Circle().stroke(Theme.ink.opacity(0.6), lineWidth: 2).frame(width: 92, height: 92)
                }
            }
            .disabled(trackingState != .tracking || isCapturing)
            .opacity(trackingState == .tracking && !isCapturing ? 1 : 0.4)
            .accessibilityLabel("Capture face")

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
        if isCapturing { return "Capturing…" }
        if trackingState == .tracking { return "Tap to capture" }
        return "Waiting for face…"
    }

    // MARK: - "Capturing…" overlay

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
