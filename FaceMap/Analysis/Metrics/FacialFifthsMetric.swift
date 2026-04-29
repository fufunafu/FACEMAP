import Foundation
import simd

/// Horizontal fifths: at the canthal level the face should divide into five widths,
/// each approximately equal to one palpebral fissure (eye width).
/// We measure five horizontal segments left-to-right:
///   1. exocanthion R → endocanthion R is invalid (those define the right eye width).
/// Standard construction: total face width = 5 × eye-width, with each fifth being:
///   [outer cheek R → exo R], [exo R → endo R], [endo R → endo L], [endo L → exo L], [exo L → outer cheek L]
/// We approximate "outer cheek" with the zygion landmark.
/// Reports the worst absolute deviation of any fifth from 20% of total width.
struct FacialFifthsMetric: FaceMetric {
    static let id = "facial.fifths"
    static let displayName = "Facial fifths"
    var regions: [FacialRegion] { [.templeL, .templeR, .midfaceL, .midfaceR] }

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        do {
            let zR     = try face.require(.zygionR)
            let exoR   = try face.require(.exocanthionR)
            let endoR  = try face.require(.endocanthionR)
            let endoL  = try face.require(.endocanthionL)
            let exoL   = try face.require(.exocanthionL)
            let zL     = try face.require(.zygionL)

            // Use only the X coordinate (horizontal) since all six points sit roughly on a horizontal line.
            let xs: [Float] = [zR.x, exoR.x, endoR.x, endoL.x, exoL.x, zL.x].sorted()
            let widths: [Double] = (0..<5).map { Double(xs[$0 + 1] - xs[$0]) }
            let total = widths.reduce(0, +)
            guard total > 0 else { return Self.failure("zero face width") }

            let fractions = widths.map { $0 / total }
            let target: ClosedRange<Double> = 0...0.10    // ±10% deviation per fifth
            let deviations = fractions.map { abs($0 - 0.20) }
            let worst = deviations.max() ?? 0

            // Map deviant fifth(s) to regions. Index order after sorting: [outer-R, eye-R, inter-eye, eye-L, outer-L].
            let worstIdx = deviations.firstIndex(of: worst) ?? 0
            let flagged: [FacialRegion]
            if worst <= 0.10 {
                flagged = []
            } else {
                switch worstIdx {
                case 0: flagged = [.templeR, .midfaceR]
                case 1: flagged = [.midfaceR]
                case 2: flagged = []                       // inter-eye width is structural; can't be filled
                case 3: flagged = [.midfaceL]
                default: flagged = [.templeL, .midfaceL]
                }
            }

            let deviation = max(0, worst - target.upperBound)
            let notes = "fifths " + fractions.map { String(format: "%.0f%%", $0 * 100) }.joined(separator: " / ")
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
