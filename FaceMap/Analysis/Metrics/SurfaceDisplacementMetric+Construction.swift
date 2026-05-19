import Foundation
import simd
import UIKit

extension SurfaceDisplacementMetric: VisuallyExplainable {

    /// Same pair set the metric measures. Kept in sync by hand.
    private static let pairsForConstruction: [(FacialRegion, FacialRegion)] = [
        (.midfaceL,     .midfaceR),
        (.tearTroughL,  .tearTroughR),
        (.marionetteL,  .marionetteR),
        (.prejowlL,     .prejowlR),
        (.jawlineL,     .jawlineR),
    ]

    private static let thresholdMeters: Double = 0.0015

    func construction(for face: AnalyzableFace) -> MetricConstruction? {
        let verts = face.captured.vertices
        guard !verts.isEmpty else { return nil }

        var markers: [ConstructionMarker] = []
        var segments: [ConstructionSegment] = []
        var labels: [ConstructionLabel] = []

        for (l, r) in Self.pairsForConstruction {
            guard let li = FaceLandmarkIndices.regionVertices[l], !li.isEmpty,
                  let ri = FaceLandmarkIndices.regionVertices[r], !ri.isEmpty else { continue }

            let lc = centroid(of: li, in: verts)
            let rc = centroid(of: ri, in: verts)
            let diffMeters = Double(abs(lc.z - rc.z))
            let color = colorForDeficit(diffMeters)

            markers.append(ConstructionMarker(position: lc, color: color))
            markers.append(ConstructionMarker(position: rc, color: color))

            let zBump: Float = 0.001
            let lcFront = SIMD3<Float>(lc.x, lc.y, lc.z + zBump)
            let rcFront = SIMD3<Float>(rc.x, rc.y, rc.z + zBump)
            segments.append(ConstructionSegment(start: lcFront, end: rcFront, color: color))

            let mid = (lcFront + rcFront) / 2
            let labelPos = SIMD3<Float>(mid.x, mid.y, mid.z + 0.008)
            let text = String(format: "%.1f mm", diffMeters * 1000)
            labels.append(ConstructionLabel(position: labelPos, text: text, color: color))
        }

        return MetricConstruction(metricId: Self.id, markers: markers,
                                  segments: segments, labels: labels)
    }

    private func centroid(of indices: [Int], in verts: [SIMD3<Float>]) -> SIMD3<Float> {
        var sum = SIMD3<Float>(repeating: 0); var count = 0
        for i in indices where i >= 0 && i < verts.count {
            sum += verts[i]; count += 1
        }
        return count > 0 ? sum / Float(count) : sum
    }

    private func colorForDeficit(_ meters: Double) -> UIColor {
        let mm = meters * 1000
        let severity: MetricResult.Severity
        switch mm {
        case ..<1.5:  severity = .normal
        case ..<3.0:  severity = .mild
        case ..<5.0:  severity = .moderate
        default:      severity = .significant
        }
        return UIColor(severity.color(in: .facialShape))
    }
}
