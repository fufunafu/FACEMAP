import SwiftUI

/// Domain-level summary row in the analysis-screen overview. One row per
/// `FaceDomain` that has metrics, showing the worst severity tint, the domain name,
/// and a one-line summary ("4 flagged · worst Facial fifths 43.9%"). Tapping pushes
/// to the per-domain detail view.
struct CategoryRow: View {
    let domain: FaceDomain
    let results: [MetricResult]
    /// Optional formatter for the worst result's value text. Falls back to its `notes`.
    var valueFormatter: (MetricResult) -> String = { $0.notes ?? "" }

    private var flagged: [MetricResult] {
        results.filter { !$0.isWithinTarget }
    }

    private var worstSeverity: MetricResult.Severity {
        flagged.map { $0.severity }.max { rank($0) < rank($1) } ?? .normal
    }

    /// Worst flagged metric: highest severity, ties broken by largest finite deviation.
    private var worst: MetricResult? {
        flagged.max { a, b in
            let ra = rank(a.severity), rb = rank(b.severity)
            if ra != rb { return ra < rb }
            let da = a.deviation.isFinite ? a.deviation : 0
            let db = b.deviation.isFinite ? b.deviation : 0
            return da < db
        }
    }

    private func rank(_ s: MetricResult.Severity) -> Int {
        switch s {
        case .normal:      return 0
        case .mild:        return 1
        case .moderate:    return 2
        case .significant: return 3
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SeverityDot(domain: domain, severity: worstSeverity, size: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(domain.displayName)
                    .font(Type.metricName)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(summaryLine)
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(Type.captionStrong)
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var summaryLine: String {
        guard !results.isEmpty else { return "No metrics" }
        if flagged.isEmpty {
            return "\(results.count) metrics · all within target"
        }
        if let w = worst {
            let value = valueFormatter(w)
            if value.isEmpty {
                return "\(flagged.count) flagged · worst \(w.metricName)"
            }
            return "\(flagged.count) flagged · worst \(w.metricName) (\(value))"
        }
        return "\(flagged.count) flagged"
    }
}
