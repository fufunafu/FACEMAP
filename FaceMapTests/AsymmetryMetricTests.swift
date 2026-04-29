import XCTest
import simd
@testable import FaceMap

final class AsymmetryMetricTests: XCTestCase {

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

    func test_perfectlyMirroredPairs_isWithinTarget() {
        // For each pair, place L at +X and R at -X (mirrored). Expect zero asymmetry.
        let face = makeFace([
            .templeL:     SIMD3( 0.07, 0.05, 0),
            .templeR:     SIMD3(-0.07, 0.05, 0),
            .midfaceL:    SIMD3( 0.05, 0.0,  0.02),
            .midfaceR:    SIMD3(-0.05, 0.0,  0.02),
            .browL:       SIMD3( 0.025, 0.08, 0.01),
            .browR:       SIMD3(-0.025, 0.08, 0.01),
            .tearTroughL: SIMD3( 0.02, 0.05, 0.005),
            .tearTroughR: SIMD3(-0.02, 0.05, 0.005),
            .nasolabialL: SIMD3( 0.02, -0.05, 0.01),
            .nasolabialR: SIMD3(-0.02, -0.05, 0.01),
            .marionetteL: SIMD3( 0.025, -0.08, 0.005),
            .marionetteR: SIMD3(-0.025, -0.08, 0.005),
            .prejowlL:    SIMD3( 0.04, -0.10, 0),
            .prejowlR:    SIMD3(-0.04, -0.10, 0),
            .jawlineL:    SIMD3( 0.06, -0.09, 0),
            .jawlineR:    SIMD3(-0.06, -0.09, 0),
        ])
        let r = AsymmetryMetric().evaluate(face)
        XCTAssertTrue(r.isWithinTarget, "expected ≤1.5mm worst, got \(r.value * 1000) mm")
        XCTAssertTrue(r.regions.isEmpty)
    }

    func test_midfaceShiftedRight_flagsBothMidfaces() {
        // Right midface 4 mm flatter (closer to midline) than the left.
        let face = makeFace([
            .midfaceL: SIMD3( 0.05, 0.0, 0.02),
            .midfaceR: SIMD3(-0.046, 0.0, 0.02),     // 4 mm of asymmetry
            // Other pairs symmetric
            .templeL:     SIMD3( 0.07, 0.05, 0),
            .templeR:     SIMD3(-0.07, 0.05, 0),
            .browL:       SIMD3( 0.025, 0.08, 0.01),
            .browR:       SIMD3(-0.025, 0.08, 0.01),
            .tearTroughL: SIMD3( 0.02, 0.05, 0.005),
            .tearTroughR: SIMD3(-0.02, 0.05, 0.005),
            .nasolabialL: SIMD3( 0.02, -0.05, 0.01),
            .nasolabialR: SIMD3(-0.02, -0.05, 0.01),
            .marionetteL: SIMD3( 0.025, -0.08, 0.005),
            .marionetteR: SIMD3(-0.025, -0.08, 0.005),
            .prejowlL:    SIMD3( 0.04, -0.10, 0),
            .prejowlR:    SIMD3(-0.04, -0.10, 0),
            .jawlineL:    SIMD3( 0.06, -0.09, 0),
            .jawlineR:    SIMD3(-0.06, -0.09, 0),
        ])
        let r = AsymmetryMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.midfaceL))
        XCTAssertTrue(r.regions.contains(.midfaceR))
        // Worst pair distance should be ~4 mm.
        XCTAssertEqual(r.value * 1000, 4.0, accuracy: 0.5)
    }

    func test_value_isReportedInMeters() {
        // Sanity: a 2 mm asymmetry on one pair should yield value ≈ 0.002.
        let face = makeFace([
            .browL: SIMD3( 0.025, 0.08, 0.01),
            .browR: SIMD3(-0.023, 0.08, 0.01),       // 2 mm
        ])
        let r = AsymmetryMetric().evaluate(face)
        XCTAssertEqual(r.value, 0.002, accuracy: 0.0005)
    }

    func test_divergentChartPairs_areConsistentWithMetric() {
        let face = makeFace([
            .midfaceL: SIMD3( 0.05, 0.0, 0.02),
            .midfaceR: SIMD3(-0.046, 0.0, 0.02),     // 4 mm asymmetry
            .templeL:  SIMD3( 0.07, 0.05, 0),
            .templeR:  SIMD3(-0.07, 0.05, 0),
        ])
        let pairs = AsymmetryDivergentChart.computePairs(from: face)
        let midface = pairs.first { $0.leftRegion == .midfaceL && $0.rightRegion == .midfaceR }
        XCTAssertNotNil(midface)
        XCTAssertEqual(abs(midface?.signedDelta ?? 0), 0.004, accuracy: 0.0005)

        let temple = pairs.first { $0.leftRegion == .templeL && $0.rightRegion == .templeR }
        XCTAssertEqual(abs(temple?.signedDelta ?? 1), 0.0, accuracy: 0.0005)
    }

    func test_metricResult_carriesSymmetryDomain() {
        let face = makeFace([:])
        let r = AsymmetryMetric().evaluate(face)
        XCTAssertEqual(r.domain, .symmetry)
    }
}
