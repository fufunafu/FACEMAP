import Foundation
import simd
import UIKit

extension FacialThirdsMetric: VisuallyExplainable {

    func construction(for face: AnalyzableFace) -> MetricConstruction? {
        guard let trichion  = face.position(of: .trichion),
              let glabella  = face.position(of: .glabella),
              let subnasale = face.position(of: .subnasale),
              let menton    = face.position(of: .menton),
              let zR        = face.position(of: .zygionR),
              let zL        = face.position(of: .zygionL) else { return nil }

        let upper  = trichion.distance(to: glabella)
        let middle = glabella.distance(to: subnasale)
        let lower  = subnasale.distance(to: menton)
        let total  = upper + middle + lower
        guard total > 0 else { return nil }

        let upperFrac  = upper  / total
        let middleFrac = middle / total
        let lowerFrac  = lower  / total
        let third = 1.0 / 3.0

        let xL: Float = zR.x - 0.005
        let xR: Float = zL.x + 0.005

        let baseColor = UIColor(MetricResult.Severity.normal.color(in: .symmetry))
        let alertColor = UIColor(MetricResult.Severity.moderate.color(in: .symmetry))

        var markers: [ConstructionMarker] = []
        var segments: [ConstructionSegment] = []
        var labels: [ConstructionLabel] = []

        func guide(at p: SIMD3<Float>) {
            let zBump: Float = 0.001
            let a = SIMD3<Float>(xL, p.y, p.z + zBump)
            let b = SIMD3<Float>(xR, p.y, p.z + zBump)
            segments.append(ConstructionSegment(start: a, end: b, color: baseColor))
            markers.append(ConstructionMarker(position: p, color: baseColor))
        }

        guide(at: trichion)
        guide(at: glabella)
        guide(at: subnasale)
        guide(at: menton)

        func label(between a: SIMD3<Float>, _ b: SIMD3<Float>, fraction: Double) {
            let mid = (a + b) / 2
            let pos = SIMD3<Float>(0, mid.y, mid.z + 0.012)
            let dev = abs(fraction - third)
            let color = dev > 0.05 ? alertColor : baseColor
            labels.append(
                ConstructionLabel(
                    position: pos,
                    text: String(format: "%.0f%%", fraction * 100),
                    color: color
                )
            )
        }

        label(between: trichion, glabella,   fraction: upperFrac)
        label(between: glabella, subnasale,  fraction: middleFrac)
        label(between: subnasale, menton,    fraction: lowerFrac)

        return MetricConstruction(metricId: Self.id, markers: markers,
                                  segments: segments, labels: labels)
    }
}
