import SwiftUI

/// Full-bleed `FaceMeshOverlay` presented as a sheet. Used when the practitioner taps
/// the mesh thumbnail in the analysis-screen header — the mesh fills the screen with
/// the canonical viewer-controls strip (preset jumps + reset) and a close button.
struct MeshFullScreen: View {
    @Environment(\.dismiss) private var dismiss
    let face: CapturedFace
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    let regionDomain: [FacialRegion: FaceDomain]

    @StateObject private var controller = FaceMeshController()

    var body: some View {
        ZStack(alignment: .top) {
            FaceMeshOverlay(
                face: face,
                regionSeverity: regionSeverity,
                regionDomain: regionDomain,
                controller: controller
            )
            .ignoresSafeArea()

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Close")
                .padding(.top, 8)
                .padding(.trailing, 16)
            }

            VStack {
                Spacer()
                ViewerControls(controller: controller)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Shared preset-strip + reset button. Used in the full-screen viewer and in the
/// per-domain detail screen.
struct ViewerControls: View {
    let controller: FaceMeshController

    var body: some View {
        HStack(spacing: 6) {
            ForEach(FaceViewPreset.allCases) { preset in
                Button {
                    controller.setPreset(preset)
                } label: {
                    Text(preset.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.white)
            }
            Spacer(minLength: 4)
            Button {
                controller.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .padding(8)
            }
            .background(.ultraThinMaterial, in: Circle())
            .foregroundStyle(.white)
            .accessibilityLabel("Reset view")
        }
    }
}
