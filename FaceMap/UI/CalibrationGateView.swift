import SwiftUI

/// Session-scoped escape hatch for the calibration gate. Deliberately NOT persisted:
/// the "evaluation only" override resets on every launch, so a practitioner can
/// never drift into routine clinical use on placeholder landmark indices. All
/// calibration warning banners and PDF strips remain regardless of this flag.
final class CalibrationGateSession: ObservableObject {
    static let shared = CalibrationGateSession()
    @Published var evaluationOverrideGranted = false
}

/// Rendered in place of the capture camera while landmark calibration is
/// incomplete. The shipped landmark indices are placeholders — metrics computed
/// on them measure arbitrary points — so clinical capture is gated on a completed
/// calibration (README pre-production checklist #2).
struct CalibrationGateView: View {
    @ObservedObject var store = LandmarkCalibrationStore.shared
    @ObservedObject var session = CalibrationGateSession.shared

    @State private var showingOverrideConfirmation = false

    private var total: Int { AnatomicalLandmark.allCases.count }
    private var done: Int { store.calibratedCount }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "scope")
                .font(.system(size: 44))
                .foregroundStyle(Theme.ink)

            Text("Calibrate before clinical capture")
                .font(Type.titleLarge)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text("FaceMap's measurements depend on anatomical landmarks that must be calibrated once on a real captured mesh — you can use your own face. It takes about two minutes and is stored on this device only.")
                .font(Type.callout)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                ProgressView(value: Double(done), total: Double(total))
                    .tint(Theme.ink)
                Text("\(done) of \(total) landmarks calibrated")
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
            }
            .padding(.horizontal, 24)

            NavigationLink {
                CalibrationCaptureScreen()
            } label: {
                Text(done == 0 ? "Calibrate now" : "Resume calibration")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue uncalibrated (evaluation only)") {
                showingOverrideConfirmation = true
            }
            .font(Type.caption)
            .foregroundStyle(Theme.inkDim)
            .padding(.bottom, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .confirmationDialog(
            "Capture without calibration?",
            isPresented: $showingOverrideConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue for evaluation only", role: .destructive) {
                session.evaluationOverrideGranted = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Measurements will use placeholder landmark positions and are not clinically meaningful. This choice lasts until you quit the app.")
        }
    }
}
