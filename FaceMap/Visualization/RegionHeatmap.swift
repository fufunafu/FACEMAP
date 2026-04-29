import SwiftUI

/// Compact summary list rendered next to (or below) the 3D mesh on the analysis screen.
/// Each row is a flagged region + the worst severity any metric reported for it.
struct RegionHeatmapView: View {
    let regionSeverity: [FacialRegion: MetricResult.Severity]
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
                Button { onSelect(region) } label: {
                    HStack {
                        Circle().fill(severity.color).frame(width: 12, height: 12)
                        Text(region.displayName)
                        Spacer()
                        Text(severity.rawValue.capitalized)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

extension MetricResult.Severity {
    var color: Color {
        switch self {
        case .normal:      return .green
        case .mild:        return .yellow
        case .moderate:    return .orange
        case .significant: return .red
        }
    }
}
