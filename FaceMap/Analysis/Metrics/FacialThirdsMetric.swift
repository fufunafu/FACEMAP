import Foundation
import simd

/// Vertical thirds: trichion → glabella, glabella → subnasale, subnasale → menton.
/// Reports the maximum absolute deviation of any third from 1/3 of the total face height.
/// Target: each third within ±5% of equal.
struct FacialThirdsMetric: FaceMetric {
    static let id = "facial.thirds"
    static let displayName = "Facial thirds"
    static let domain: FaceDomain = .symmetry
    var regions: [FacialRegion] { [.forehead, .midfaceL, .midfaceR, .chin, .lipUpper, .lipLower] }

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        do {
            let trichion  = try face.require(.trichion)
            let glabella  = try face.require(.glabella)
            let subnasale = try face.require(.subnasale)
            let menton    = try face.require(.menton)

            let upper  = trichion.distance(to: glabella)
            let middle = glabella.distance(to: subnasale)
            let lower  = subnasale.distance(to: menton)
            let total  = upper + middle + lower
            guard total > 0 else { return Self.failure("zero face height") }

            let upperFrac  = upper  / total
            let middleFrac = middle / total
            let lowerFrac  = lower  / total

            // The metric value is the worst-case absolute deviation from 1/3.
            let third = 1.0 / 3.0
            let deviations = [upperFrac, middleFrac, lowerFrac].map { abs($0 - third) }
            let worst = deviations.max() ?? 0
            let target: ClosedRange<Double> = 0...0.05    // ±5% of total face height

            // Map the most-deviant third to the appropriate regions.
            let worstIdx = deviations.firstIndex(of: worst) ?? 0
            let flagged: [FacialRegion]
            switch worstIdx {
            case 0: flagged = worst > 0.05 ? [.forehead] : []
            case 1: flagged = worst > 0.05 ? [.midfaceL, .midfaceR] : []
            default: flagged = worst > 0.05 ? [.lipUpper, .lipLower, .chin] : []
            }

            let deviation = max(0, worst - target.upperBound)
            let notes = String(
                format: "upper %.1f%%, middle %.1f%%, lower %.1f%% of total",
                upperFrac * 100, middleFrac * 100, lowerFrac * 100
            )
            return MetricResult(
                metricId: Self.id,
                metricName: Self.displayName,
                domain: Self.domain,
                value: worst,
                target: target,
                deviation: deviation,
                confidence: 1.0,
                regions: flagged,
                notes: notes
            )
        } catch {
            return Self.failure(String(describing: error))
        }
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName, domain: domain,
                     value: .nan, target: 0...0.05, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
