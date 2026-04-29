import Foundation
import simd

/// Angle of the line from medial canthus (endocanthion) to lateral canthus (exocanthion),
/// relative to horizontal. Positive = lateral canthus higher than medial (typical).
/// Target: 4°–7° on each side.
/// Reports the worst per-side deviation from the target. Low/negative tilt flags tear-trough region.
struct CanthalTiltMetric: FaceMetric {
    static let id = "ocular.canthalTilt"
    static let displayName = "Canthal tilt"
    var regions: [FacialRegion] { [.tearTroughL, .tearTroughR, .midfaceL, .midfaceR] }

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        do {
            let endoR = try face.require(.endocanthionR)
            let exoR  = try face.require(.exocanthionR)
            let endoL = try face.require(.endocanthionL)
            let exoL  = try face.require(.exocanthionL)

            // Tilt = atan2(Δy, Δx) in screen space, where +y is up. ARKit face-local +y is up,
            // so the calculation is direct. Right side: vector goes outward (more negative x).
            let tiltR = Double(atan2(exoR.y - endoR.y, abs(exoR.x - endoR.x))) * 180.0 / .pi
            let tiltL = Double(atan2(exoL.y - endoL.y, abs(exoL.x - endoL.x))) * 180.0 / .pi

            let target: ClosedRange<Double> = 4.0...7.0
            // Per-side absolute deviations from the target range.
            let devR = max(0, max(target.lowerBound - tiltR, tiltR - target.upperBound))
            let devL = max(0, max(target.lowerBound - tiltL, tiltL - target.upperBound))
            let worst = max(devR, devL)
            // Value is reported as the *minimum* tilt (the side most likely to need attention).
            let value = min(tiltR, tiltL)

            var flagged: [FacialRegion] = []
            if tiltR < target.lowerBound { flagged.append(contentsOf: [.tearTroughR, .midfaceR]) }
            if tiltL < target.lowerBound { flagged.append(contentsOf: [.tearTroughL, .midfaceL]) }

            let notes = String(format: "right %.1f°, left %.1f°", tiltR, tiltL)
            return MetricResult(
                metricId: Self.id, metricName: Self.displayName,
                value: value, target: target, deviation: worst,
                confidence: 1.0, regions: flagged, notes: notes
            )
        } catch {
            return Self.failure(String(describing: error))
        }
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName,
                     value: .nan, target: 4.0...7.0, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
