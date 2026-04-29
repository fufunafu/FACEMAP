import XCTest
import simd
@testable import FaceMap

final class FacialFifthsMetricTests: XCTestCase {
    func test_equalFifths_isWithinTarget() {
        let face = SyntheticFace.make([
            .zygionR:       SIMD3(-0.05, 0, 0),
            .exocanthionR:  SIMD3(-0.03, 0, 0),
            .endocanthionR: SIMD3(-0.01, 0, 0),
            .endocanthionL: SIMD3( 0.01, 0, 0),
            .exocanthionL:  SIMD3( 0.03, 0, 0),
            .zygionL:       SIMD3( 0.05, 0, 0),
        ])
        let r = FacialFifthsMetric().evaluate(face)
        XCTAssertTrue(r.isWithinTarget, "got value=\(r.value)")
        XCTAssertEqual(r.regions, [])
    }

    func test_oversizeOuterFifth_flagsTempleAndMidface() {
        let face = SyntheticFace.make([
            .zygionR:       SIMD3(-0.05, 0, 0),
            .exocanthionR:  SIMD3(-0.03, 0, 0),
            .endocanthionR: SIMD3(-0.01, 0, 0),
            .endocanthionL: SIMD3( 0.01, 0, 0),
            .exocanthionL:  SIMD3( 0.03, 0, 0),
            .zygionL:       SIMD3( 0.07, 0, 0),    // wider outer-left
        ])
        let r = FacialFifthsMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.templeL) || r.regions.contains(.midfaceL),
                      "got regions=\(r.regions)")
    }
}
