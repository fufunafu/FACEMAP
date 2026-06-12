import Foundation

/// Resting expression asymmetry from ARKit blendshape coefficients.
///
/// Captures are taken at neutral expression, so every coefficient should be near
/// zero and — more importantly — *equal* across sides. A persistent left/right gap
/// in a paired coefficient (brow, eye, smile, frown…) indicates asymmetric resting
/// muscle tone or habitual unilateral lines, which is exactly the FAS "Expression"
/// facet's static/dynamic-line concern.
///
/// Reports the worst absolute L−R activation gap across the tracked pairs (0…1).
/// Target: ≤ 0.15 — below typical inter-frame jitter, above genuine tonal asymmetry.
struct ExpressionAsymmetryMetric: FaceMetric {
    static let id = "expression.restingAsymmetry"
    static let displayName = "Resting expression asymmetry"
    static let domain: FaceDomain = .expression

    var regions: [FacialRegion] {
        [.browL, .browR, .perioral, .nasolabialL, .nasolabialR, .marionetteL, .marionetteR]
    }

    /// Paired ARKit blendshape keys (`ARFaceAnchor.BlendShapeLocation` raw values)
    /// and the patient regions implicated when that pair is asymmetric.
    /// `left`/`right` are ARKit's labels, which refer to the patient's left/right.
    struct Pair {
        let name: String
        let left: String
        let right: String
        let regionsL: [FacialRegion]
        let regionsR: [FacialRegion]
    }

    static let pairs: [Pair] = [
        Pair(name: "brow lower", left: "browDown_L", right: "browDown_R",
             regionsL: [.browL], regionsR: [.browR]),
        Pair(name: "eye squint", left: "eyeSquint_L", right: "eyeSquint_R",
             regionsL: [.tearTroughL], regionsR: [.tearTroughR]),
        Pair(name: "smile", left: "mouthSmile_L", right: "mouthSmile_R",
             regionsL: [.nasolabialL, .perioral], regionsR: [.nasolabialR, .perioral]),
        Pair(name: "frown", left: "mouthFrown_L", right: "mouthFrown_R",
             regionsL: [.marionetteL], regionsR: [.marionetteR]),
        Pair(name: "cheek squint", left: "cheekSquint_L", right: "cheekSquint_R",
             regionsL: [.midfaceL], regionsR: [.midfaceR]),
        Pair(name: "dimple", left: "mouthDimple_L", right: "mouthDimple_R",
             regionsL: [.perioral], regionsR: [.perioral]),
    ]

    static let target: ClosedRange<Double> = 0.0...0.15

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        let shapes = face.captured.blendShapes
        guard !shapes.isEmpty else {
            return Self.failure("No blendshape data on this capture")
        }

        var worstGap = 0.0
        var worstPair: Pair? = nil
        var worstSideIsLeft = false
        var measuredPairs = 0

        for pair in Self.pairs {
            guard let l = shapes[pair.left], let r = shapes[pair.right] else { continue }
            measuredPairs += 1
            let gap = Double(abs(l - r))
            if gap > worstGap {
                worstGap = gap
                worstPair = pair
                worstSideIsLeft = l > r
            }
        }

        guard measuredPairs > 0 else {
            return Self.failure("No paired blendshape coefficients present")
        }

        let outOfRange = worstGap > Self.target.upperBound
        let flagged: [FacialRegion] = (outOfRange && worstPair != nil)
            ? (worstSideIsLeft ? worstPair!.regionsL : worstPair!.regionsR)
            : []
        let notes = worstPair.map {
            String(format: "worst pair: %@ (Δ %.2f, %@ side higher)",
                   $0.name, worstGap, worstSideIsLeft ? "left" : "right")
        }

        return MetricResult(
            metricId: Self.id, metricName: Self.displayName, domain: Self.domain,
            value: worstGap, target: Self.target,
            deviation: max(0, worstGap - Self.target.upperBound),
            confidence: 1.0, regions: flagged, notes: notes
        )
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName, domain: domain,
                     value: .nan, target: target, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
