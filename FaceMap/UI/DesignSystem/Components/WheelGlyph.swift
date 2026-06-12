import SwiftUI

/// Compact five-sector glyph summarising the Aesthetic Wheel at a glance — one 72°
/// sector per FAS facet, clockwise from 12 o'clock in `FaceDomain.allCases` order
/// (matching `AestheticWheel` and `LogoMark`). Each sector takes the worst severity
/// of its facet's metrics and tints in the facet hue. Empty facets render as the
/// hairline grey so the glyph is honest about coverage. Used in the analysis-screen
/// header where the full `AestheticWheel` would look empty.
struct WheelGlyph: View {
    let results: [MetricResult]
    var diameter: CGFloat = 28

    /// Sectors clockwise from 12 o'clock.
    private static let sectorOrder: [FaceDomain] = FaceDomain.allCases

    var body: some View {
        ZStack {
            ForEach(Array(Self.sectorOrder.enumerated()), id: \.offset) { idx, domain in
                Sector(index: idx)
                    .fill(fillColor(for: domain))
            }
            // Hairline spokes to separate the five sectors.
            Path { p in
                let r = diameter / 2
                let centre = CGPoint(x: r, y: r)
                for i in 0..<Self.sectorOrder.count {
                    let a = (-90.0 + Double(i) * 72.0) * .pi / 180
                    p.move(to: centre)
                    p.addLine(to: CGPoint(x: centre.x + r * CGFloat(cos(a)),
                                          y: centre.y + r * CGFloat(sin(a))))
                }
            }
            .stroke(Theme.canvas, lineWidth: 1)

            Circle()
                .stroke(Theme.hairline, lineWidth: 1)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .accessibilityElement()
        .accessibilityLabel(accessibilityDescription)
    }

    private func fillColor(for domain: FaceDomain) -> Color {
        let inDomain = results.filter { $0.domain == domain && !$0.isWithinTarget }
        guard let worst = inDomain.max(by: { severityRank($0.severity) < severityRank($1.severity) }) else {
            // Domain has no flagged metrics — either no metrics yet, or all within target.
            let hasAnyMetric = results.contains { $0.domain == domain }
            return hasAnyMetric ? domain.hue.opacity(0.18) : Theme.hairline
        }
        return worst.severity.color(in: domain)
    }

    private func severityRank(_ s: MetricResult.Severity) -> Int {
        switch s {
        case .normal:      return 0
        case .mild:        return 1
        case .moderate:    return 2
        case .significant: return 3
        }
    }

    private var accessibilityDescription: String {
        let summaries = Self.sectorOrder.map { d -> String in
            let n = results.filter { $0.domain == d && !$0.isWithinTarget }.count
            return n == 0 ? "\(d.displayName): clear" : "\(d.displayName): \(n) flagged"
        }
        return "Aesthetic wheel summary. " + summaries.joined(separator: ". ")
    }

    /// One of five 72° pie wedges, clockwise from 12 o'clock.
    private struct Sector: Shape {
        let index: Int

        func path(in rect: CGRect) -> Path {
            let r = min(rect.width, rect.height) / 2
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            // Angles in standard SwiftUI clockwise convention (0 = right, 90 = down, etc.).
            let start = Angle(degrees: -90 + Double(index) * 72)
            let end   = Angle(degrees: -90 + Double(index + 1) * 72)
            var p = Path()
            p.move(to: centre)
            p.addArc(center: centre, radius: r, startAngle: start, endAngle: end, clockwise: false)
            p.closeSubpath()
            return p
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        WheelGlyph(results: [], diameter: 56)
        WheelGlyph(results: [
            MetricResult(metricId: "x", metricName: "x", domain: .symmetry,
                         value: 0.4, target: 0...0.05, deviation: 0.35,
                         confidence: 1, regions: [.midfaceL], notes: nil)
        ], diameter: 56)
    }
    .padding()
    .background(Theme.canvas)
    .preferredColorScheme(.light)
}
