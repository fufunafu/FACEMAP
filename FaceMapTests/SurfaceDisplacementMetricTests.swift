import XCTest
import simd
@testable import FaceMap

final class SurfaceDisplacementMetricTests: XCTestCase {

    /// Build a vertex array sized to fit every region-vertex index, then assign each region's
    /// vertices to the supplied position. Regions not specified get [0,0,0].
    private func makeFace(_ regionPositions: [FacialRegion: SIMD3<Float>]) -> AnalyzableFace {
        let allIndices = FaceLandmarkIndices.regionVertices.values.flatMap { $0 }
        let maxIdx = (allIndices.max() ?? 0) + 1
        var verts = Array(repeating: SIMD3<Float>(repeating: 0), count: max(maxIdx, 500))
        for (region, p) in regionPositions {
            guard let indices = FaceLandmarkIndices.regionVertices[region] else { continue }
            for i in indices where i < verts.count { verts[i] = p }
        }
        return AnalyzableFace(vertices: verts)
    }

    func test_balancedZ_isWithinTarget() {
        // Both sides of every pair sit at the same Z — no deficit.
        let face = makeFace([
            .midfaceL:    SIMD3( 0.05, 0.0,  0.04),
            .midfaceR:    SIMD3(-0.05, 0.0,  0.04),
            .tearTroughL: SIMD3( 0.02, 0.05, 0.03),
            .tearTroughR: SIMD3(-0.02, 0.05, 0.03),
            .marionetteL: SIMD3( 0.025, -0.08, 0.025),
            .marionetteR: SIMD3(-0.025, -0.08, 0.025),
            .prejowlL:    SIMD3( 0.04, -0.10, 0.02),
            .prejowlR:    SIMD3(-0.04, -0.10, 0.02),
            .jawlineL:    SIMD3( 0.06, -0.09, 0.015),
            .jawlineR:    SIMD3(-0.06, -0.09, 0.015),
        ])
        let r = SurfaceDisplacementMetric().evaluate(face)
        XCTAssertTrue(r.isWithinTarget,
                      "expected ≤1.5mm worst, got \(r.value * 1000) mm; notes=\(r.notes ?? "")")
        XCTAssertTrue(r.regions.isEmpty)
    }

    func test_leftMidfaceFlatter_flagsLeftOnly() {
        // Left midface 3 mm less projected (lower Z) than right.
        let face = makeFace([
            .midfaceL:    SIMD3( 0.05, 0.0,  0.037),  // 3 mm flatter
            .midfaceR:    SIMD3(-0.05, 0.0,  0.040),
            // Other pairs symmetric
            .tearTroughL: SIMD3( 0.02, 0.05, 0.03),
            .tearTroughR: SIMD3(-0.02, 0.05, 0.03),
            .marionetteL: SIMD3( 0.025, -0.08, 0.025),
            .marionetteR: SIMD3(-0.025, -0.08, 0.025),
            .prejowlL:    SIMD3( 0.04, -0.10, 0.02),
            .prejowlR:    SIMD3(-0.04, -0.10, 0.02),
            .jawlineL:    SIMD3( 0.06, -0.09, 0.015),
            .jawlineR:    SIMD3(-0.06, -0.09, 0.015),
        ])
        let r = SurfaceDisplacementMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.midfaceL),
                      "expected the flatter side flagged; got \(r.regions)")
        XCTAssertFalse(r.regions.contains(.midfaceR))
        XCTAssertEqual(r.value * 1000, 3.0, accuracy: 0.5)
    }

    func test_value_inMeters_andDomainStructural() {
        let face = makeFace([
            .prejowlL: SIMD3( 0.04, -0.10, 0.018),    // 2 mm flatter
            .prejowlR: SIMD3(-0.04, -0.10, 0.020),
        ])
        let r = SurfaceDisplacementMetric().evaluate(face)
        XCTAssertEqual(r.value, 0.002, accuracy: 0.0005)
        XCTAssertEqual(r.domain, .structural)
    }
}
