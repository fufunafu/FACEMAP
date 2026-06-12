import XCTest
import simd
@testable import FaceMap

final class ExpressionAsymmetryMetricTests: XCTestCase {
    private func face(blendShapes: [String: Float]) -> AnalyzableFace {
        AnalyzableFace(vertices: [SIMD3<Float>(0, 0, 0)], blendShapes: blendShapes)
    }

    func test_symmetricRest_isWithinTarget() {
        let r = ExpressionAsymmetryMetric().evaluate(face(blendShapes: [
            "browDown_L": 0.05, "browDown_R": 0.05,
            "mouthSmile_L": 0.10, "mouthSmile_R": 0.10,
            "eyeSquint_L": 0.02, "eyeSquint_R": 0.02,
        ]))
        XCTAssertTrue(r.isWithinTarget)
        XCTAssertEqual(r.value, 0.0, accuracy: 1e-9)
        XCTAssertTrue(r.regions.isEmpty)
    }

    func test_asymmetricSmile_flagsHigherSideRegions() {
        let r = ExpressionAsymmetryMetric().evaluate(face(blendShapes: [
            "mouthSmile_L": 0.40, "mouthSmile_R": 0.05,
            "browDown_L": 0.02, "browDown_R": 0.02,
        ]))
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertEqual(r.value, 0.35, accuracy: 1e-6)
        // Left activation is higher → left-side regions implicated.
        XCTAssertTrue(r.regions.contains(.nasolabialL))
        XCTAssertTrue(r.regions.contains(.perioral))
        XCTAssertFalse(r.regions.contains(.nasolabialR))
        XCTAssertEqual(r.domain, .expression)
    }

    func test_worstPair_winsAcrossPairs() {
        let r = ExpressionAsymmetryMetric().evaluate(face(blendShapes: [
            "mouthSmile_L": 0.10, "mouthSmile_R": 0.05,   // gap 0.05
            "browDown_L": 0.02, "browDown_R": 0.30,       // gap 0.28 ← worst
        ]))
        XCTAssertEqual(r.value, 0.28, accuracy: 1e-6)
        XCTAssertTrue(r.regions.contains(.browR))
        XCTAssertTrue(r.notes?.contains("brow lower") == true)
    }

    func test_missingBlendshapes_returnsUnavailable() {
        let r = ExpressionAsymmetryMetric().evaluate(face(blendShapes: [:]))
        XCTAssertTrue(r.value.isNaN)
        XCTAssertEqual(r.confidence, 0)
        XCTAssertTrue(r.notes?.contains("Unavailable") == true)
    }

    func test_unpairedKeys_returnsUnavailable() {
        // Keys present but none of the tracked pairs complete.
        let r = ExpressionAsymmetryMetric().evaluate(face(blendShapes: [
            "jawOpen": 0.1, "mouthSmile_L": 0.2,
        ]))
        XCTAssertTrue(r.value.isNaN)
    }
}
