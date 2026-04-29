import Foundation
import simd

/// Surface asymmetry across the midsagittal plane.
///
/// For each pair of laterally-symmetric regions (e.g. midfaceL ↔ midfaceR), we mirror the
/// left-side region's centroid across the X = 0 plane in face-local coordinates and measure
/// the distance to the right-side region's centroid. ARKit's face mesh is built with the
/// midsagittal plane at X = 0, so mirroring is a simple sign flip.
///
/// The metric value is the **worst pair distance in millimetres**. Pairs exceeding the
/// threshold (1.5 mm by default) flag both regions in the result so practitioners can see
/// which sides need attention.
///
/// Limitations of v0.2:
/// - Compares regional **centroids only**. A region with translated *and* rotated asymmetry
///   may report less than its true point-cloud asymmetry. v0.3 will compare per-vertex.
/// - Assumes the head is held level during capture. A tilted head produces apparent
///   asymmetry; the capture screen's framing guide nudges users toward neutral pose.
/// - 1.5 mm threshold is a starting point — should be calibrated per practitioner preference.
struct AsymmetryMetric: FaceMetric {
    static let id = "facial.asymmetry"
    static let displayName = "Facial asymmetry"
    static let domain: FaceDomain = .symmetry

    /// Threshold (metres) above which a pair is considered clinically asymmetric.
    private static let thresholdMeters: Double = 0.0015      // 1.5 mm

    /// Laterally-symmetric region pairs we measure. Midline regions (forehead, chin,
    /// lipUpper, lipLower, perioral) are excluded — they are not expected to be paired.
    private static let pairs: [(FacialRegion, FacialRegion)] = [
        (.templeL,      .templeR),
        (.browL,        .browR),
        (.tearTroughL,  .tearTroughR),
        (.midfaceL,     .midfaceR),
        (.nasolabialL,  .nasolabialR),
        (.marionetteL,  .marionetteR),
        (.prejowlL,     .prejowlR),
        (.jawlineL,     .jawlineR),
    ]

    var regions: [FacialRegion] {
        Self.pairs.flatMap { [$0.0, $0.1] }
    }

    func evaluate(_ face: AnalyzableFace) -> MetricResult {
        let verts = face.captured.vertices
        guard !verts.isEmpty else { return Self.failure("no vertices") }

        var worstMeters: Double = 0
        var flagged: [FacialRegion] = []
        var notes: [String] = []

        for (l, r) in Self.pairs {
            guard let li = FaceLandmarkIndices.regionVertices[l], !li.isEmpty,
                  let ri = FaceLandmarkIndices.regionVertices[r], !ri.isEmpty else { continue }

            let lc = centroid(of: li, in: verts)
            let rc = centroid(of: ri, in: verts)
            // Mirror the left centroid across X = 0 (midsagittal plane in ARKit face-local).
            let lcMirrored = SIMD3<Float>(-lc.x, lc.y, lc.z)
            let dist = Double(simd_distance(lcMirrored, rc))

            if dist > Self.thresholdMeters {
                flagged.append(l)
                flagged.append(r)
                notes.append(String(format: "%@↔︎%@ %.1f mm",
                                    l.displayName, r.displayName, dist * 1000))
            }
            worstMeters = max(worstMeters, dist)
        }

        let target: ClosedRange<Double> = 0...Self.thresholdMeters
        let deviation = max(0, worstMeters - target.upperBound)
        let summary: String
        if notes.isEmpty {
            summary = String(format: "all pairs ≤ %.1f mm", Self.thresholdMeters * 1000)
        } else {
            summary = notes.joined(separator: " · ")
        }

        return MetricResult(
            metricId: Self.id,
            metricName: Self.displayName,
            domain: Self.domain,
            value: worstMeters,
            target: target,
            deviation: deviation,
            confidence: 1.0,
            regions: flagged,
            notes: summary
        )
    }

    private func centroid(of indices: [Int], in verts: [SIMD3<Float>]) -> SIMD3<Float> {
        var sum = SIMD3<Float>(repeating: 0)
        var count = 0
        for i in indices where i >= 0 && i < verts.count {
            sum += verts[i]
            count += 1
        }
        return count > 0 ? sum / Float(count) : sum
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName, domain: domain,
                     value: .nan, target: 0...thresholdMeters, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
