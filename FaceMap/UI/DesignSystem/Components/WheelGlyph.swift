import SwiftUI

/// Compact four-quadrant glyph summarising the Aesthetic Wheel at a glance.
/// Each quadrant takes the worst severity of its domain's metrics and tints in the
/// domain hue. Empty domains render as the hairline grey so the glyph is honest about
/// coverage. Used in the analysis-screen header where the full `AestheticWheel` would
/// look empty (only one domain populated in v0.2).
struct WheelGlyph: View {
    let results: [MetricResult]
    var diameter: CGFloat = 28

    /// Order matches `FaceDomain.wheelQuadrant`: TL, TR, BL, BR.
    private static let quadrantOrder: [FaceDomain] = [.mechanical, .optical, .symmetry, .structural]

    var body: some View {
        ZStack {
            ForEach(Array(Self.quadrantOrder.enumerated()), id: \.offset) { idx, domain in
                Quadrant(index: idx)
                    .fill(fillColor(for: domain))
            }
            // Hairline cross to separate quadrants.
            Path { p in
                let r = diameter / 2
                p.move(to: CGPoint(x: r,  y: 0))
                p.addLine(to: CGPoint(x: r,  y: diameter))
                p.move(to: CGPoint(x: 0,  y: r))
                p.addLine(to: CGPoint(x: diameter, y: r))
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
        let summaries = Self.quadrantOrder.map { d -> String in
            let n = results.filter { $0.domain == d && !$0.isWithinTarget }.count
            return n == 0 ? "\(d.displayName): clear" : "\(d.displayName): \(n) flagged"
        }
        return "Aesthetic wheel summary. " + summaries.joined(separator: ". ")
    }

    /// One of four pie wedges, in the order TL → TR → BL → BR.
    private struct Quadrant: Shape {
        let index: Int

        func path(in rect: CGRect) -> Path {
            let r = min(rect.width, rect.height) / 2
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            // Start angles in standard SwiftUI clockwise convention (0 = right, 90 = down, etc.).
            let starts: [Double] = [180, 270, 90, 0]   // TL, TR, BL, BR
            let start = Angle(degrees: starts[index])
            let end   = Angle(degrees: starts[index] + 90)
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
