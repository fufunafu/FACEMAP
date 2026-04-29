import SwiftUI
import ARKit

struct CaptureScreen: View {
    @EnvironmentObject var store: CaseStore
    @State private var captureRequested = false
    @State private var trackingState: FaceCaptureView.Coordinator.TrackingState = .noFace
    @State private var capturedFace: CapturedFace?
    @State private var navigateToAnalysis = false

    var body: some View {
        ZStack {
            if FaceTracking.isSupportedOnThisDevice {
                FaceCaptureView(
                    onSnapshot: { face in
                        capturedFace = face
                        navigateToAnalysis = true
                    },
                    onTrackingState: { state in trackingState = state },
                    captureRequested: $captureRequested
                )
                .ignoresSafeArea()
            } else {
                unsupportedView
            }

            VStack {
                statusBadge
                Spacer()
                captureControls
            }
            .padding()
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let face = capturedFace {
                AnalysisScreen(face: face)
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle().fill(badgeColor).frame(width: 10, height: 10)
            Text(badgeText).font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var badgeColor: Color {
        switch trackingState {
        case .unsupported: return .red
        case .noFace:      return .orange
        case .tracking:    return .green
        }
    }

    private var badgeText: String {
        switch trackingState {
        case .unsupported: return "TrueDepth not available"
        case .noFace:      return "Looking for a face…"
        case .tracking:    return "Face tracking — hold still"
        }
    }

    private var captureControls: some View {
        Button {
            captureRequested = true
        } label: {
            ZStack {
                Circle().fill(.white).frame(width: 78, height: 78)
                Circle().stroke(Color.white, lineWidth: 4).frame(width: 88, height: 88)
            }
        }
        .disabled(trackingState != .tracking)
        .opacity(trackingState == .tracking ? 1 : 0.45)
    }

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash").font(.system(size: 56))
            Text("This device does not support face tracking.")
                .multilineTextAlignment(.center)
            Text("FaceMap requires a TrueDepth camera (iPhone X or newer, or recent iPad Pro).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
