import SwiftUI

/// Standard metric row used in the Analysis screen, RegionDetail, and PDF.
struct MetricRow: View {
    let result: MetricResult
    let domain: FaceDomain
    var valueText: String
    var trailingChevron: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SeverityDot(domain: domain, severity: result.severity, size: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(result.metricName)
                        .font(Type.metricName)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    DomainBadge(domain: domain)
                }
                Text(valueText)
                    .font(Type.measurement)
                    .foregroundStyle(Theme.inkDim)
                if let n = result.notes {
                    Text(n)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }

            if trailingChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}
