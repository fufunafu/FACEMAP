import SwiftUI

/// Compact summary list rendered next to (or below) the 3D mesh on the analysis screen.
/// Each row is a flagged region + the worst severity any metric reported for it,
/// shown in the domain hue of the metric that flagged it.
struct RegionHeatmapView: View {
    /// Severity per region.
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    /// Domain (for colouring) per region. Falls back to `.symmetry`.
    let regionDomain: [FacialRegion: FaceDomain]
    var onSelect: (FacialRegion) -> Void = { _ in }

    private var sorted: [(FacialRegion, MetricResult.Severity)] {
        let order: [MetricResult.Severity] = [.significant, .moderate, .mild, .normal]
        return regionSeverity.sorted { a, b in
            (order.firstIndex(of: a.value) ?? 4) < (order.firstIndex(of: b.value) ?? 4)
        }
    }

    var body: some View {
        if sorted.isEmpty {
            ContentUnavailableView(
                "No regions flagged",
                systemImage: "checkmark.seal",
                description: Text("All measured ratios fall within target ranges.")
            )
            .padding()
        } else {
            List(sorted, id: \.0) { (region, severity) in
                let domain = regionDomain[region] ?? .symmetry
                Button { onSelect(region) } label: {
                    HStack(spacing: 12) {
                        SeverityDot(domain: domain, severity: severity, size: 12)
                        Text(region.displayName)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        DomainBadge(domain: domain)
                        Text(severity.rawValue.capitalized)
                            .font(Type.caption.monospacedDigit())
                            .foregroundStyle(Theme.inkDim)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
        }
    }
}
