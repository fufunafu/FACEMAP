import Foundation
import simd

/// Selected phi (≈1.618) ratios used in aesthetic analysis. We pick two well-attested ratios
/// for v0.1 and report the worst deviation from phi:
///   • mouth width / nose width — Marquardt; phi ≈ 1.618
///   • lower-third height / nose length — Ricketts E-line variant; phi ≈ 1.618
/// Target: ratios within ±10% of phi.
struct GoldenRatioMetric: FaceMetric {
    static let id = "facial.goldenRatio"
    static let displayName = "Golden ratio (selected)"
    static let phi = 1.6180339887

    var regions: [FacialRegion] { [.lipUpper, .lipLower, .perioral, .chin] }

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        do {
            // Mouth width / nose width
            let cheilionR = try face.require(.cheilionR)
            let cheilionL = try face.require(.cheilionL)
            let alarR     = try face.require(.alarBaseR)
            let alarL     = try face.require(.alarBaseL)
            let mouthWidth = cheilionR.distance(to: cheilionL)
            let noseWidth  = alarR.distance(to: alarL)
            guard noseWidth > 0 else { return Self.failure("zero nose width") }
            let r1 = mouthWidth / noseWidth

            // Lower-third height / nose length (subnasale → menton over nasion → subnasale)
            let nasion    = try face.require(.nasion)
            let subnasale = try face.require(.subnasale)
            let menton    = try face.require(.menton)
            let noseLength = nasion.distance(to: subnasale)
            let lowerThird = subnasale.distance(to: menton)
            guard noseLength > 0 else { return Self.failure("zero nose length") }
            let r2 = lowerThird / noseLength

            let dev1 = abs(r1 - Self.phi) / Self.phi
            let dev2 = abs(r2 - Self.phi) / Self.phi
            let worst = max(dev1, dev2)
            let target: ClosedRange<Double> = 0...0.10

            var flagged: [FacialRegion] = []
            if dev1 > 0.10 { flagged.append(contentsOf: [.lipUpper, .lipLower, .perioral]) }
            if dev2 > 0.10 { flagged.append(.chin) }

            let deviation = max(0, worst - target.upperBound)
            let notes = String(
                format: "mouth/nose width = %.2f (φ %.2f); lower-third/nose-length = %.2f",
                r1, Self.phi, r2
            )
            return MetricResult(
                metricId: Self.id, metricName: Self.displayName,
                value: worst, target: target, deviation: deviation,
                confidence: 1.0, regions: flagged, notes: notes
            )
        } catch {
            return Self.failure(String(describing: error))
        }
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName,
                     value: .nan, target: 0...0.10, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
