import Foundation
import simd
import UIKit

extension CanthalTiltMetric: VisuallyExplainable {

    func construction(for face: AnalyzableFace) -> MetricConstruction? {
        guard let endoR = face.position(of: .endocanthionR),
              let exoR  = face.position(of: .exocanthionR),
              let endoL = face.position(of: .endocanthionL),
              let exoL  = face.position(of: .exocanthionL) else { return nil }

        let tiltR = Double(atan2(exoR.y - endoR.y, abs(exoR.x - endoR.x))) * 180.0 / .pi
        let tiltL = Double(atan2(exoL.y - endoL.y, abs(exoL.x - endoL.x))) * 180.0 / .pi
        let target: ClosedRange<Double> = 4.0...7.0

        let colorR = severityColor(for: tiltR, target: target)
        let colorL = severityColor(for: tiltL, target: target)

        var markers: [ConstructionMarker] = []
        var segments: [ConstructionSegment] = []
        var labels: [ConstructionLabel] = []

        for (endo, exo, color, value) in [
            (endoR, exoR, colorR, tiltR),
            (endoL, exoL, colorL, tiltL),
        ] {
            markers.append(ConstructionMarker(position: endo, color: color))
            markers.append(ConstructionMarker(position: exo,  color: color))

            let zBump: Float = 0.001
            let a = SIMD3<Float>(endo.x, endo.y, endo.z + zBump)
            let b = SIMD3<Float>(exo.x,  exo.y,  exo.z  + zBump)
            segments.append(ConstructionSegment(start: a, end: b, color: color))

            let mid = (a + b) / 2
            let labelPos = SIMD3<Float>(mid.x, mid.y - 0.008, mid.z + 0.008)
            labels.append(
                ConstructionLabel(
                    position: labelPos,
                    text: String(format: "%.1f°", value),
                    color: color
                )
            )
        }

        return MetricConstruction(metricId: Self.id, markers: markers,
                                  segments: segments, labels: labels)
    }

    private func severityColor(for tilt: Double, target: ClosedRange<Double>) -> UIColor {
        let dev = max(0, max(target.lowerBound - tilt, tilt - target.upperBound))
        let severity: MetricResult.Severity
        switch dev {
        case 0:        severity = .normal
        case ..<2:     severity = .mild
        case ..<4:     severity = .moderate
        default:       severity = .significant
        }
        return UIColor(severity.color(in: .symmetry))
    }
}
