import SwiftUI

/// Filled circle whose colour encodes (domain, severity).
struct SeverityDot: View {
    let domain: FaceDomain
    let severity: MetricResult.Severity
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(severity.color(in: domain))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Theme.hairline, lineWidth: severity == .normal ? 1 : 0)
            )
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(FaceDomain.allCases) { d in
            VStack {
                Text(d.rawValue).font(.caption2).foregroundStyle(.white)
                HStack {
                    SeverityDot(domain: d, severity: .normal)
                    SeverityDot(domain: d, severity: .mild)
                    SeverityDot(domain: d, severity: .moderate)
                    SeverityDot(domain: d, severity: .significant)
                }
            }
        }
    }
    .padding()
    .background(Theme.canvas)
    .preferredColorScheme(.light)
}
