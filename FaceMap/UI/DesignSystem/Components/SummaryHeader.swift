import SwiftUI

/// Header card on `AnalysisScreen`. Replaces the old half-width black mesh + half-width
/// AestheticWheel layout. Shows a compact mesh thumbnail (tap → full-screen viewer),
/// the patient/visit label, a one-line metric summary, and a small `WheelGlyph`.
///
/// The thumbnail uses `Theme.surface` as its viewport background so it blends into the
/// card; the harsh black "spotlight" treatment is reserved for the full-screen viewer.
struct SummaryHeader: View {
    let face: CapturedFace
    let label: String
    let visitDate: Date?
    let results: [MetricResult]
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    let regionDomain: [FacialRegion: FaceDomain]
    var onOpenFullscreen: () -> Void = {}

    /// The thumbnail is non-interactive so it doesn't intercept the parent ScrollView's gestures.
    @StateObject private var thumbnailController = FaceMeshController()

    private var flaggedCount: Int {
        results.filter { !$0.isWithinTarget }.count
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Mesh thumbnail — tap to enter fullscreen.
            Button(action: onOpenFullscreen) {
                ZStack(alignment: .bottomTrailing) {
                    FaceMeshOverlay(
                        face: face,
                        regionSeverity: regionSeverity,
                        regionDomain: regionDomain,
                        controller: thumbnailController,
                        interactive: false,
                        backgroundColor: UIColor(Theme.surfaceRaised)
                    )
                    .frame(width: 120, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(6)
                        .background(.regularMaterial, in: Circle())
                        .padding(6)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open 3D viewer fullscreen")

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(Type.titleLarge)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        if let date = visitDate {
                            Text(date, style: .date)
                                .font(Type.caption)
                                .foregroundStyle(Theme.inkDim)
                        }
                    }
                    Spacer(minLength: 8)
                    WheelGlyph(results: results, diameter: 32)
                }

                Text(summaryLine)
                    .font(Type.callout)
                    .foregroundStyle(Theme.inkDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var summaryLine: String {
        guard !results.isEmpty else { return "Analysing…" }
        if flaggedCount == 0 {
            return "\(results.count) metrics · all within target"
        }
        return "\(results.count) metrics · \(flaggedCount) flagged"
    }
}
