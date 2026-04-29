import SwiftUI

/// Mirrors Dr Andreas Nikolis's published Facial Aesthetic framework: four
/// quadrants (one per `FaceDomain`), three concentric severity rings (1/2/3),
/// metrics plotted as dots on radial axes inside their domain quadrant.
///
/// Tap a quadrant to drill into that domain.
struct AestheticWheel: View {
    /// Pre-grouped metric results, keyed by domain. Empty domains are rendered
    /// as ghosted quadrants ("not yet measured").
    let resultsByDomain: [FaceDomain: [MetricResult]]
    var diameter: CGFloat = 260
    var showsLabels: Bool = true
    var onTapDomain: ((FaceDomain) -> Void)? = nil

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                drawWheel(ctx: ctx, size: size)
            }

            if showsLabels {
                labelOverlay
                    .frame(width: diameter, height: diameter)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            guard let onTapDomain else { return }
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let dx = location.x - center.x
            let dy = location.y - center.y
            let dist = hypot(dx, dy)
            guard dist > diameter * 0.18, dist < diameter * 0.5 else { return }
            // CG angle: 0° = +x, 90° = +y (down), 180° = -x, 270° = -y (up).
            var deg = atan2(dy, dx) * 180.0 / .pi
            if deg < 0 { deg += 360 }
            onTapDomain(domain(forAngle: deg))
        }
    }

    // MARK: - Drawing

    private func drawWheel(ctx: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        let outer  = radius * 0.92
        let inner  = radius * 0.22

        // 1. Quadrant fills (domain hue at low opacity, outer band brighter)
        for d in FaceDomain.allCases {
            let (start, end) = arcAngles(for: d, gapDegrees: 4)
            let fill = Path { p in
                p.move(to: center)
                p.addArc(center: center, radius: outer,
                         startAngle: start, endAngle: end, clockwise: false)
                p.closeSubpath()
            }
            ctx.fill(fill, with: .radialGradient(
                Gradient(stops: [
                    .init(color: d.fillHue.opacity(0.10), location: 0.0),
                    .init(color: d.fillHue.opacity(0.45), location: 1.0),
                ]),
                center: center, startRadius: inner, endRadius: outer
            ))
        }

        // 2. Outer ring band — black-on-light, mirrors the reference's external label band
        let outerBand = radius * 0.96
        let outerStroke = Path { p in
            p.addArc(center: center, radius: outerBand,
                     startAngle: .degrees(0), endAngle: .degrees(360),
                     clockwise: false)
        }
        ctx.stroke(outerStroke, with: .color(Theme.ink), lineWidth: 5)

        // 3. Cut quadrant gaps over the band — light slits (canvas) so the four
        //    sectors read as separate.
        for d in FaceDomain.allCases {
            let edges = quadrantEdges(for: d)
            for edgeDeg in edges {
                let path = Path { p in
                    p.move(to: center)
                    let rad = edgeDeg * .pi / 180
                    let endPoint = CGPoint(
                        x: center.x + cos(rad) * (radius * 1.05),
                        y: center.y + sin(rad) * (radius * 1.05)
                    )
                    p.addLine(to: endPoint)
                }
                ctx.stroke(path, with: .color(Theme.canvas), lineWidth: 7)
            }
        }

        // 4. Three concentric severity rings (dark on light)
        for ring in 1...3 {
            let r = inner + (outer - inner) * CGFloat(ring) / 3.0
            let path = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                              width: r * 2, height: r * 2))
            ctx.stroke(path, with: .color(Theme.ink.opacity(0.22)),
                       style: StrokeStyle(lineWidth: 0.5))
        }

        // 5. Per-metric axes + dots inside each quadrant
        for d in FaceDomain.allCases {
            let metrics = resultsByDomain[d] ?? []
            guard !metrics.isEmpty else { continue }
            let (start, end) = arcAngles(for: d, gapDegrees: 12)
            let span = end.radians - start.radians
            let step = span / Double(metrics.count + 1)

            for (i, m) in metrics.enumerated() {
                let angle = start.radians + step * Double(i + 1)
                // Axis line
                let p1 = polar(center: center, angle: angle, radius: inner)
                let p2 = polar(center: center, angle: angle, radius: outer)
                var axis = Path()
                axis.move(to: p1)
                axis.addLine(to: p2)
                ctx.stroke(axis, with: .color(Theme.ink.opacity(0.18)),
                           style: StrokeStyle(lineWidth: 0.5))

                // Dot at severity ring
                let ring = m.severity.ringIndex
                let dotR: CGFloat = ring == 0 ? 4 : 6
                let dotRadius = ring == 0
                    ? inner + (outer - inner) * 0.08
                    : inner + (outer - inner) * CGFloat(ring) / 3.0
                let p = polar(center: center, angle: angle, radius: dotRadius)
                let dotColor: Color = ring == 0
                    ? Theme.ink.opacity(0.45)
                    : d.hue
                ctx.fill(
                    Path(ellipseIn: CGRect(x: p.x - dotR, y: p.y - dotR,
                                           width: dotR * 2, height: dotR * 2)),
                    with: .color(dotColor)
                )
            }
        }

        // 6. Center hub — light disc with a thin dark ring.
        let hub = Path(ellipseIn: CGRect(
            x: center.x - inner, y: center.y - inner,
            width: inner * 2, height: inner * 2))
        ctx.fill(hub, with: .color(Theme.canvas))
        ctx.stroke(hub, with: .color(Theme.ink.opacity(0.55)), lineWidth: 1)
    }

    // MARK: - Labels overlay (straight text, positioned outside each arc)

    private var labelOverlay: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let positions: [(FaceDomain, CGPoint)] = FaceDomain.allCases.map { d in
                let mid = midAngle(for: d) * .pi / 180
                let pr = r * 1.02
                return (d, CGPoint(
                    x: geo.size.width / 2 + cos(mid) * pr,
                    y: geo.size.height / 2 + sin(mid) * pr
                ))
            }
            ZStack {
                ForEach(positions, id: \.0) { d, p in
                    Text(d.displayName.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.ink)
                        .position(p)
                }
                // Centre scale labels (1, 2, 3)
                ForEach(1...3, id: \.self) { ring in
                    let inner = r * 0.22
                    let outer = r * 0.92
                    let rr = inner + (outer - inner) * CGFloat(ring) / 3.0
                    Text("\(ring)")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.inkMuted)
                        .position(x: geo.size.width / 2 + 4,
                                  y: geo.size.height / 2 - rr - 4)
                }
            }
        }
    }

    // MARK: - Geometry helpers

    /// Arc angles for a domain in CG coordinates (y-down, 0° = +x, increasing CW).
    private func arcAngles(for domain: FaceDomain, gapDegrees: Double) -> (Angle, Angle) {
        let half = gapDegrees / 2
        let bounds = quadrantBoundsDegrees(domain)
        return (.degrees(bounds.start + half), .degrees(bounds.end - half))
    }

    private func quadrantBoundsDegrees(_ domain: FaceDomain) -> (start: Double, end: Double) {
        switch domain {
        case .mechanical: return (180, 270)  // top-left
        case .optical:    return (270, 360)  // top-right
        case .structural: return (0, 90)     // bottom-right
        case .symmetry:   return (90, 180)   // bottom-left
        }
    }

    private func quadrantEdges(for domain: FaceDomain) -> [Double] {
        let b = quadrantBoundsDegrees(domain)
        return [b.start, b.end]
    }

    private func midAngle(for domain: FaceDomain) -> Double {
        let b = quadrantBoundsDegrees(domain)
        return (b.start + b.end) / 2
    }

    private func domain(forAngle deg: Double) -> FaceDomain {
        // Map clockwise CG angle to quadrant.
        switch deg {
        case 0..<90:    return .structural
        case 90..<180:  return .symmetry
        case 180..<270: return .mechanical
        default:        return .optical
        }
    }

    private func polar(center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius)
    }
}

// MARK: - Convenience initializer from a flat result list

extension AestheticWheel {
    init(results: [MetricResult],
         diameter: CGFloat = 260,
         showsLabels: Bool = true,
         onTapDomain: ((FaceDomain) -> Void)? = nil)
    {
        var grouped: [FaceDomain: [MetricResult]] = [:]
        for r in results {
            grouped[r.domain, default: []].append(r)
        }
        self.init(resultsByDomain: grouped,
                  diameter: diameter,
                  showsLabels: showsLabels,
                  onTapDomain: onTapDomain)
    }
}

#Preview("Empty wheel") {
    AestheticWheel(resultsByDomain: [:])
        .padding(40)
        .background(Theme.canvas)
        .preferredColorScheme(.light)
}

#Preview("With sample data") {
    let sample: [MetricResult] = [
        MetricResult(metricId: "facial.thirds", metricName: "Facial thirds",
                     domain: .symmetry, value: 0.07, target: 0...0.05,
                     deviation: 0.02, confidence: 1, regions: [], notes: nil),
        MetricResult(metricId: "facial.fifths", metricName: "Facial fifths",
                     domain: .symmetry, value: 0.04, target: 0...0.10,
                     deviation: 0, confidence: 1, regions: [], notes: nil),
        MetricResult(metricId: "facial.goldenRatio", metricName: "Golden ratio",
                     domain: .symmetry, value: 0.18, target: 0...0.10,
                     deviation: 0.08, confidence: 1, regions: [], notes: nil),
        MetricResult(metricId: "ocular.canthalTilt", metricName: "Canthal tilt",
                     domain: .symmetry, value: 2.0, target: 4.0...7.0,
                     deviation: 2.0, confidence: 1, regions: [], notes: nil),
    ]
    return AestheticWheel(results: sample, diameter: 280)
        .padding(40)
        .background(Theme.canvas)
        .preferredColorScheme(.light)
}
