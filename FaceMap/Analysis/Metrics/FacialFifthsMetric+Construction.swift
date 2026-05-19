import Foundation
import simd
import UIKit

extension FacialFifthsMetric: VisuallyExplainable {

    func construction(for face: AnalyzableFace) -> MetricConstruction? {
        guard let zR    = face.position(of: .zygionR),
              let exoR  = face.position(of: .exocanthionR),
              let endoR = face.position(of: .endocanthionR),
              let endoL = face.position(of: .endocanthionL),
              let exoL  = face.position(of: .exocanthionL),
              let zL    = face.position(of: .zygionL) else { return nil }

        let pts = [zR, exoR, endoR, endoL, exoL, zL].sorted { $0.x < $1.x }
        let widths: [Double] = (0..<5).map { Double(pts[$0 + 1].x - pts[$0].x) }
        let total = widths.reduce(0, +)
        guard total > 0 else { return nil }
        let fractions = widths.map { $0 / total }

        let canthY: Float = (exoR.y + endoR.y + endoL.y + exoL.y) / 4
        let yTop:   Float = canthY + 0.012
        let yBot:   Float = canthY - 0.012

        let baseColor = UIColor(MetricResult.Severity.normal.color(in: .symmetry))
        let alertColor = UIColor(MetricResult.Severity.moderate.color(in: .symmetry))

        var markers: [ConstructionMarker] = []
        var segments: [ConstructionSegment] = []
        var labels: [ConstructionLabel] = []

        let zBump: Float = 0.001
        for p in pts {
            let top = SIMD3<Float>(p.x, yTop, p.z + zBump)
            let bot = SIMD3<Float>(p.x, yBot, p.z + zBump)
            segments.append(ConstructionSegment(start: top, end: bot, color: baseColor))
            markers.append(ConstructionMarker(position: p, color: baseColor))
        }

        let leftEnd  = SIMD3<Float>(pts.first!.x, canthY, pts.first!.z + zBump)
        let rightEnd = SIMD3<Float>(pts.last!.x,  canthY, pts.last!.z  + zBump)
        segments.append(ConstructionSegment(start: leftEnd, end: rightEnd, color: baseColor))

        for i in 0..<5 {
            let xMid = (pts[i].x + pts[i + 1].x) / 2
            let dev = abs(fractions[i] - 0.20)
            let color = dev > 0.10 ? alertColor : baseColor
            let pos = SIMD3<Float>(xMid, yBot - 0.012, pts[i].z + 0.008)
            labels.append(
                ConstructionLabel(
                    position: pos,
                    text: String(format: "%.0f%%", fractions[i] * 100),
                    color: color
                )
            )
        }

        return MetricConstruction(metricId: Self.id, markers: markers,
                                  segments: segments, labels: labels)
    }
}
