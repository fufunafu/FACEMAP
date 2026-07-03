import SwiftUI

/// Full-bleed `FaceMeshOverlay` presented as a sheet. Used when the practitioner taps
/// the mesh thumbnail in the analysis-screen header — the mesh fills the screen with
/// the canonical viewer-controls strip (preset jumps + reset), surface/heatmap
/// toggles, and a close button.
struct MeshFullScreen: View {
    @Environment(\.dismiss) private var dismiss
    let face: CapturedFace
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    let regionDomain: [FacialRegion: FaceDomain]
    /// Frontal clinical photo — enables the photo-textured surface when the capture
    /// carries projection data.
    var photoJPEG: Data? = nil
    /// Per-metric geometric overlays to render on the mesh. Empty = clean mesh.
    var constructions: [MetricConstruction] = []

    @StateObject private var controller = FaceMeshController()
    @State private var surface: FaceMeshStyle.Surface = .automatic
    @State private var heatmapVisible = true

    /// The photo/clay toggle only appears when a photo texture is possible at all.
    private var photoToggleAvailable: Bool {
        photoJPEG != nil && face.hasPhotoProjectionData
    }

    private var heatmapToggleAvailable: Bool {
        regionSeverity.values.contains { $0 != .normal }
    }

    var body: some View {
        ZStack(alignment: .top) {
            FaceMeshOverlay(
                face: face,
                regionSeverity: regionSeverity,
                regionDomain: regionDomain,
                controller: controller,
                photoJPEG: photoJPEG,
                constructions: constructions
            )
            .ignoresSafeArea()

            HStack {
                if photoToggleAvailable || heatmapToggleAvailable {
                    surfaceControls
                        .padding(.top, 8)
                        .padding(.leading, 16)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(Type.control)
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

    /// Photo ↔ clay surface toggle + heatmap visibility toggle.
    private var surfaceControls: some View {
        HStack(spacing: 6) {
            if photoToggleAvailable {
                Button {
                    surface = (surface == .clay) ? .photo : .clay
                    controller.setSurface(surface)
                } label: {
                    Label(surface == .clay ? "Photo" : "Clay",
                          systemImage: surface == .clay ? "person.crop.square" : "cube")
                        .font(Type.captionStrong)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.white)
                .accessibilityLabel(surface == .clay ? "Show photo surface" : "Show clay surface")
            }
            if heatmapToggleAvailable {
                Button {
                    heatmapVisible.toggle()
                    controller.setHeatmapVisible(heatmapVisible)
                } label: {
                    Image(systemName: heatmapVisible ? "circle.hexagongrid.fill" : "circle.hexagongrid")
                        .font(Type.captionStrong)
                        .padding(8)
                }
                .background(.ultraThinMaterial, in: Circle())
                .foregroundStyle(.white)
                .accessibilityLabel(heatmapVisible ? "Hide region heatmap" : "Show region heatmap")
            }
        }
    }
}

/// Shared preset-strip + reset button. Used in the full-screen viewer and in the
/// per-domain detail screen. Mesh-viewport overlay: white-on-black is deliberate
/// (spotlight viewer), but sizes come from the Type scale.
struct ViewerControls: View {
    let controller: FaceMeshController

    var body: some View {
        HStack(spacing: 6) {
            ForEach(FaceViewPreset.allCases) { preset in
                Button {
                    controller.setPreset(preset)
                } label: {
                    Text(preset.label)
                        .font(Type.captionStrong)
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
                    .font(Type.captionStrong)
                    .padding(8)
            }
            .background(.ultraThinMaterial, in: Circle())
            .foregroundStyle(.white)
            .accessibilityLabel("Reset view")
        }
    }
}
