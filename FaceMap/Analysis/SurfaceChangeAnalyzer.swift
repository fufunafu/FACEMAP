import Foundation
import simd

/// One region's surface change between two visits.
struct RegionChange: Identifiable, Hashable {
    var id: String { region.rawValue }
    let region: FacialRegion
    /// Mean anterior-projection change in metres. ARKit face-local Z is the
    /// out-of-face axis, so positive = the region projects further forward at the
    /// later visit (volume gain), negative = volume loss.
    let deltaZMeters: Double
    let vertexCount: Int
    /// The noise floor this change was judged against — the fixed 0.3 mm baseline,
    /// raised when either capture recorded high temporal jitter (see
    /// `SurfaceChangeAnalyzer.noiseFloor(from:to:)`).
    var noiseFloorMeters: Double = SurfaceChangeAnalyzer.noiseFloorMeters

    var exceedsNoiseFloor: Bool {
        abs(deltaZMeters) >= noiseFloorMeters
    }
}

/// Visit-over-visit surface change per facial region — the objective
/// "did the filler do what we planned" measurement.
///
/// Why this works without surface registration: ARKit's face mesh has fixed
/// topology, so vertex *i* is the same anatomical point in both captures and
/// per-vertex displacement is a direct subtraction. The face-local frame is
/// head-fixed by construction (the anchor's axes follow the head), so rotation
/// differences across sessions are negligible; any residual *translation* offset
/// between the two captures' anchor origins is cancelled using bony landmarks
/// that soft-tissue filler cannot move (nasion, orbital canthi).
///
/// Read the output longitudinally and against the noise floor: re-capturing the
/// same untreated face should keep every region inside `noiseFloorMeters`.
enum SurfaceChangeAnalyzer {
    /// Regional means from two back-to-back captures of the same untreated face
    /// move by roughly this much — changes below it are capture noise, not tissue.
    /// This is the FLOOR; `noiseFloor(from:to:)` raises it for jittery captures.
    static let noiseFloorMeters: Double = 0.0003   // 0.3 mm

    /// Comparison-specific noise floor. When both captures carry a quality record,
    /// their per-vertex temporal jitters (independent captures → variances add in
    /// quadrature) set a conservative 2σ bound, never below the 0.3 mm baseline.
    /// Legacy captures without jitter stats fall back to the baseline.
    static func noiseFloor(from earlier: CapturedFace, to later: CapturedFace) -> Double {
        guard let jitterA = earlier.quality?.meanJitterMM,
              let jitterB = later.quality?.meanJitterMM else { return noiseFloorMeters }
        let combinedMeters = 2 * sqrt(Double(jitterA * jitterA + jitterB * jitterB)) / 1000
        return max(noiseFloorMeters, combinedMeters)
    }

    /// Bony landmarks essentially unaffected by soft-tissue fillers, used to cancel
    /// systematic offset between the two captures. Trichion is excluded (hairline
    /// edge detection is unstable); zygion is excluded (cheek filler can shift the
    /// overlying skin surface).
    static let stableLandmarks: [AnatomicalLandmark] = [
        .nasion, .endocanthionR, .endocanthionL, .exocanthionR, .exocanthionL,
    ]

    /// Per-region mean projection change from `earlier` to `later`, sorted by
    /// magnitude (largest change first). Empty when the meshes are missing or
    /// their topologies don't match.
    static func regionChanges(from earlier: CapturedFace, to later: CapturedFace) -> [RegionChange] {
        let a = earlier.vertices
        let b = later.vertices
        guard !a.isEmpty, a.count == b.count else { return [] }

        let offset = stableOffset(a: a, b: b)
        let floor = noiseFloor(from: earlier, to: later)

        var out: [RegionChange] = []
        for (region, indices) in FaceLandmarkIndices.regionVertices {
            var sum: Double = 0
            var n = 0
            for i in indices where i >= 0 && i < a.count {
                sum += Double((b[i].z - offset.z) - a[i].z)
                n += 1
            }
            guard n > 0 else { continue }
            out.append(RegionChange(
                region: region,
                deltaZMeters: sum / Double(n),
                vertexCount: n,
                noiseFloorMeters: floor
            ))
        }
        return out.sorted { abs($0.deltaZMeters) > abs($1.deltaZMeters) }
    }

    /// Mean displacement of the stable bony landmarks = systematic capture offset.
    private static func stableOffset(a: [SIMD3<Float>], b: [SIMD3<Float>]) -> SIMD3<Float> {
        var sum = SIMD3<Float>(repeating: 0)
        var n: Float = 0
        for lm in stableLandmarks {
            guard let i = FaceLandmarkIndices.vertexIndex[lm], i >= 0, i < a.count else { continue }
            sum += b[i] - a[i]
            n += 1
        }
        return n > 0 ? sum / n : .zero
    }
}
