import XCTest
import simd
@testable import FaceMap

final class FacialThirdsMetricTests: XCTestCase {
    func test_idealThirds_isWithinTarget() {
        let face = SyntheticFace.make([
            .trichion:  SIMD3(0,  0.3, 0),
            .glabella:  SIMD3(0,  0.1, 0),
            .subnasale: SIMD3(0, -0.1, 0),
            .menton:    SIMD3(0, -0.3, 0),
        ])
        let r = FacialThirdsMetric().evaluate(face)
        XCTAssertTrue(r.isWithinTarget, "all thirds equal should pass; got value=\(r.value)")
        XCTAssertEqual(r.regions, [], "no regions should be flagged when within target")
        XCTAssertEqual(r.severity, .normal)
    }

    func test_dominantUpperThird_flagsForehead() {
        // Upper third is too tall: trichion→glabella spans 0.4 of total, others 0.1 and 0.2.
        let face = SyntheticFace.make([
            .trichion:  SIMD3(0,  0.3, 0),
            .glabella:  SIMD3(0, -0.1, 0),
            .subnasale: SIMD3(0, -0.2, 0),
            .menton:    SIMD3(0, -0.4, 0),
        ])
        let r = FacialThirdsMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.forehead), "got regions=\(r.regions)")
    }

    func test_dominantLowerThird_flagsLowerFaceRegions() {
        // Lower third too tall.
        let face = SyntheticFace.make([
            .trichion:  SIMD3(0,  0.2, 0),
            .glabella:  SIMD3(0,  0.1, 0),
            .subnasale: SIMD3(0,  0.0, 0),
            .menton:    SIMD3(0, -0.4, 0),
        ])
        let r = FacialThirdsMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.chin))
        XCTAssertTrue(r.regions.contains(.lipUpper) || r.regions.contains(.lipLower))
    }
}
