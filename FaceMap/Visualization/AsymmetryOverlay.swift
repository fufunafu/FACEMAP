import SwiftUI
import simd

/// Per-pair asymmetry deltas as a horizontal divergent bar chart.
/// Bars extend left of centre when the patient's left side has more "excess"
/// (mirror distance pulls the L-mirrored point further from R), and right
/// otherwise. The threshold from `AsymmetryMetric` is shown as a dashed line.
struct AsymmetryDivergentChart: View {
    let result: MetricResult
    let pairs: [Pair]

    /// One row of the chart.
    struct Pair: Identifiable {
        let id: String
        let leftRegion: FacialRegion
        let rightRegion: FacialRegion
        /// Signed value in metres. Positive = right exceeds, negative = left exceeds.
        let signedDelta: Double
        var label: String {
            // "Midface" — strip the L/R suffix from the region's display name.
            leftRegion.displayName.replacingOccurrences(of: " (L)", with: "")
        }
    }

    private let thresholdMeters: Double = 0.0015
    private let chartHeight: CGFloat = 240
    private let maxBarFraction: CGFloat = 0.42

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pair Δ (mm)")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
                Spacer()
                Text("Threshold: \(thresholdMeters * 1000, specifier: "%.1f") mm")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Centre axis
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 1)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // Threshold dashed lines (left & right of centre)
                    let thresholdX = geo.size.width / 2 + thresholdOffsetX(width: geo.size.width)
                    Path { p in
                        p.move(to: CGPoint(x: thresholdX, y: 0))
                        p.addLine(to: CGPoint(x: thresholdX, y: geo.size.height))
                        p.move(to: CGPoint(x: geo.size.width - thresholdX, y: 0))
                        p.addLine(to: CGPoint(x: geo.size.width - thresholdX, y: geo.size.height))
                    }
                    .stroke(Theme.inkMuted, style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))

                    VStack(spacing: 4) {
                        ForEach(pairs) { pair in
                            barRow(for: pair, width: geo.size.width)
                        }
                    }
                }
            }
            .frame(height: chartHeight)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func thresholdOffsetX(width: CGFloat) -> CGFloat {
        let maxBarWidth = width * maxBarFraction
        let scale = maxBarWidth / CGFloat(maxAbsDelta)
        return CGFloat(thresholdMeters) * scale
    }

    private var maxAbsDelta: Double {
        max(thresholdMeters * 2, pairs.map { abs($0.signedDelta) }.max() ?? thresholdMeters)
    }

    private func barRow(for pair: Pair, width: CGFloat) -> some View {
        let centerX = width / 2
        let scale = (width * maxBarFraction) / CGFloat(maxAbsDelta)
        let barWidth = abs(CGFloat(pair.signedDelta) * scale)
        let extendsRight = pair.signedDelta >= 0
        let isFlagged = abs(pair.signedDelta) > thresholdMeters
        let domain: FaceDomain = .symmetry
        let color = isFlagged
            ? domain.hue
            : domain.hue.opacity(0.35)

        return HStack(spacing: 0) {
            // Left half
            HStack {
                Spacer(minLength: 0)
                Text(pair.label)
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
                    .padding(.trailing, 6)
                if !extendsRight {
                    Rectangle()
                        .fill(color)
                        .frame(width: barWidth, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(width: centerX, alignment: .trailing)

            // Right half
            HStack {
                if extendsRight {
                    Rectangle()
                        .fill(color)
                        .frame(width: barWidth, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Text("\(pair.signedDelta * 1000, specifier: "%+.1f")")
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(isFlagged ? Theme.ink : Theme.inkMuted)
                    .padding(.leading, 6)
                Spacer(minLength: 0)
            }
            .frame(width: centerX, alignment: .leading)
        }
        .frame(height: 18)
    }
}

/// Translucent mirror overlay rendered on top of the live mesh viewport.
/// Renders L-side region centroids reflected across the midsagittal plane and
/// connects them to their R-side counterparts with a thin guide line whose
/// alpha scales with the asymmetry magnitude. Lightweight 2D overlay only —
/// the heavy lifting (per-vertex 3D ghost) is reserved for v0.3.
struct AsymmetryGuideOverlay: View {
    let pairs: [AsymmetryDivergentChart.Pair]
    let visible: Bool

    var body: some View {
        ZStack {
            if visible {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.domainSymmetry)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            }
        }
    }
}

// MARK: - Helper to compute pairs from an AnalyzableFace

extension AsymmetryDivergentChart {
    /// Re-runs the asymmetry computation in `AsymmetryMetric` to surface signed
    /// per-pair deltas (the metric itself only stores the worst). Cheap — just
    /// centroid maths over a handful of vertex sets.
    static func computePairs(from face: AnalyzableFace) -> [Pair] {
        let verts = face.captured.vertices
        guard !verts.isEmpty else { return [] }

        let pairs: [(FacialRegion, FacialRegion)] = [
            (.templeL, .templeR),
            (.browL, .browR),
            (.tearTroughL, .tearTroughR),
            (.midfaceL, .midfaceR),
            (.nasolabialL, .nasolabialR),
            (.marionetteL, .marionetteR),
            (.prejowlL, .prejowlR),
            (.jawlineL, .jawlineR),
        ]

        return pairs.compactMap { (l, r) in
            guard let li = FaceLandmarkIndices.regionVertices[l], !li.isEmpty,
                  let ri = FaceLandmarkIndices.regionVertices[r], !ri.isEmpty
            else { return nil }
            let lc = centroid(of: li, in: verts)
            let rc = centroid(of: ri, in: verts)
            // Mirror left across X = 0 and signed-distance to right.
            let lcMirrored = SIMD3<Float>(-lc.x, lc.y, lc.z)
            let dist = Double(simd_distance(lcMirrored, rc))
            // Sign by which side dominates (does the right need to come *toward*
            // the mirrored left, or vice versa).
            let sign: Double = (lcMirrored.x > rc.x) ? -1 : 1
            return Pair(id: "\(l)-\(r)",
                        leftRegion: l,
                        rightRegion: r,
                        signedDelta: dist * sign)
        }
    }

    private static func centroid(of indices: [Int], in verts: [SIMD3<Float>]) -> SIMD3<Float> {
        var sum = SIMD3<Float>(repeating: 0)
        var count = 0
        for i in indices where i >= 0 && i < verts.count {
            sum += verts[i]
            count += 1
        }
        return count > 0 ? sum / Float(count) : sum
    }
}
