import Foundation
import simd
import UIKit

extension AsymmetryMetric: VisuallyExplainable {

    private static let pairsForConstruction: [(FacialRegion, FacialRegion)] = [
        (.templeL,      .templeR),
        (.browL,        .browR),
        (.tearTroughL,  .tearTroughR),
        (.midfaceL,     .midfaceR),
        (.nasolabialL,  .nasolabialR),
        (.marionetteL,  .marionetteR),
        (.prejowlL,     .prejowlR),
        (.jawlineL,     .jawlineR),
    ]

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
            // Mirror left across X = 0 (midsagittal).
            let lMirrored = SIMD3<Float>(-lc.x, lc.y, lc.z)
            let dist = Double(simd_distance(lMirrored, rc))
            let color = severityColor(for: dist)

            markers.append(ConstructionMarker(position: rc, color: color))
            markers.append(ConstructionMarker(position: lMirrored, color: color))

            let zBump: Float = 0.001
            let rcFront = SIMD3<Float>(rc.x, rc.y, rc.z + zBump)
            let lmFront = SIMD3<Float>(lMirrored.x, lMirrored.y, lMirrored.z + zBump)
            segments.append(ConstructionSegment(start: rcFront, end: lmFront, color: color))

            let mid = (rcFront + lmFront) / 2
            let labelPos = SIMD3<Float>(mid.x, mid.y, mid.z + 0.008)
            labels.append(
                ConstructionLabel(
                    position: labelPos,
                    text: String(format: "%.1f mm", dist * 1000),
                    color: color
                )
            )
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

    private func severityColor(for meters: Double) -> UIColor {
        let mm = meters * 1000
        let severity: MetricResult.Severity
        switch mm {
        case ..<1.5:  severity = .normal
        case ..<3.0:  severity = .mild
        case ..<5.0:  severity = .moderate
        default:      severity = .significant
        }
        return UIColor(severity.color(in: .symmetry))
    }
}
