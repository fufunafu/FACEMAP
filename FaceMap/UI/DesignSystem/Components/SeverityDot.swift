import SwiftUI

/// Filled circle whose colour encodes (domain, severity), with a redundant
/// non-colour cue: 0–3 ink ring segments (one per severity grade) so mild
/// severities stay legible at low opacity and under colour-vision deficiency.
struct SeverityDot: View {
    let domain: FaceDomain
    let severity: MetricResult.Severity
    var size: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .fill(severity.color(in: domain))
            // 3 ring segments starting at 12 o'clock; `ringIndex` of them filled.
            ForEach(0..<3, id: \.self) { segment in
                Circle()
                    .trim(from: CGFloat(segment) / 3 + 0.03,
                          to: CGFloat(segment + 1) / 3 - 0.03)
                    .stroke(segment < severity.ringIndex ? Theme.ink : Theme.hairline,
                            style: StrokeStyle(lineWidth: max(1, size * 0.14)))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
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
