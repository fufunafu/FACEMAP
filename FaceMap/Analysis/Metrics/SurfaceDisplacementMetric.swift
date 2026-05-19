import Foundation
import simd

/// Surface displacement (volume deficit) per laterally-symmetric region.
///
/// For each region pair (e.g. midfaceL ↔ midfaceR), compares the **mean Z-coordinate**
/// of the region's vertices in ARKit face-local space — Z is the "out of face" axis,
/// so a smaller Z means the surface is more recessed. A side that is significantly
/// flatter than its contralateral counterpart is the textbook indication for volume
/// augmentation in filler planning ("left midface 2.4 mm flatter than right").
///
/// The metric value is the **worst pair Z-difference in metres** (so it sorts the same
/// way as `AsymmetryMetric`). Flagged side = the flatter member of any pair above the
/// threshold (1.5 mm by default). Domain: `.structural` — fills the structural quadrant
/// of the Aesthetic Wheel.
///
/// Limitations of v0.3:
/// - Compares regional Z **means**, not full per-vertex displacement vectors. A region
///   that is rotated relative to its mirror (rather than uniformly recessed) will
///   under-report. v0.4 should compare per-vertex L2 distance to the mirrored vertex.
/// - "Flat" is measured against the contralateral side only. Symmetric volume loss
///   (both midfaces flat) is invisible to this metric until we ship a population
///   template baseline.
/// - Cubic-centimetre conversion is not attempted in this metric — the practitioner
///   makes that call. We only report **how much** flatter, not **how much filler**.
struct SurfaceDisplacementMetric: FaceMetric {
    static let id = "structural.surfaceDisplacement"
    static let displayName = "Surface displacement"
    static let domain: FaceDomain = .facialShape

    /// Threshold (metres) above which a pair Z-difference is reported as a deficit.
    private static let thresholdMeters: Double = 0.0015      // 1.5 mm

    /// Lateral region pairs measured. Lip / perioral / chin midline regions are excluded —
    /// volume there is structural-midline and needs a template baseline (v0.4).
    private static let pairs: [(FacialRegion, FacialRegion)] = [
        (.midfaceL,     .midfaceR),
        (.tearTroughL,  .tearTroughR),
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

        var worstDeficitMeters: Double = 0
        var flagged: [FacialRegion] = []
        var notes: [String] = []

        for (l, r) in Self.pairs {
            guard let li = FaceLandmarkIndices.regionVertices[l], !li.isEmpty,
                  let ri = FaceLandmarkIndices.regionVertices[r], !ri.isEmpty else { continue }

            let lz = meanZ(of: li, in: verts)
            let rz = meanZ(of: ri, in: verts)
            let diff = Double(abs(lz - rz))

            if diff > Self.thresholdMeters {
                // The flatter side is the one with the smaller Z (less projected out of face).
                let flatter: FacialRegion = (lz < rz) ? l : r
                flagged.append(flatter)
                notes.append(String(format: "%@ %.1f mm flatter than contralateral",
                                    flatter.displayName, diff * 1000))
            }
            worstDeficitMeters = max(worstDeficitMeters, diff)
        }

        let target: ClosedRange<Double> = 0...Self.thresholdMeters
        let deviation = max(0, worstDeficitMeters - target.upperBound)
        let summary: String
        if notes.isEmpty {
            summary = String(format: "all paired regions ≤ %.1f mm Z-difference",
                             Self.thresholdMeters * 1000)
        } else {
            summary = notes.joined(separator: " · ")
        }

        return MetricResult(
            metricId: Self.id,
            metricName: Self.displayName,
            domain: Self.domain,
            value: worstDeficitMeters,
            target: target,
            deviation: deviation,
            confidence: 1.0,
            regions: flagged,
            notes: summary
        )
    }

    private func meanZ(of indices: [Int], in verts: [SIMD3<Float>]) -> Float {
        var sum: Float = 0
        var count = 0
        for i in indices where i >= 0 && i < verts.count {
            sum += verts[i].z
            count += 1
        }
        return count > 0 ? sum / Float(count) : 0
    }

    private static func failure(_ note: String) -> MetricResult {
        MetricResult(metricId: id, metricName: displayName, domain: domain,
                     value: .nan, target: 0...thresholdMeters, deviation: .nan,
                     confidence: 0, regions: [], notes: "Unavailable: \(note)")
    }
}
