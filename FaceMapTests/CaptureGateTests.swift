import XCTest
@testable import FaceMap

final class CaptureGateTests: XCTestCase {

    private func pose(pitch: Double = 0, yaw: Double = 0, roll: Double = 0) -> HeadPose {
        HeadPose(pitchDegrees: pitch, yawDegrees: yaw, rollDegrees: roll)
    }

    private func violations(target: CapturePose = .frontal,
                            pose: HeadPose? = nil,
                            blendShapes: [String: Float] = [:]) -> [CaptureGate.Violation] {
        CaptureGate.evaluate(targetPose: target,
                             pose: pose ?? self.pose(),
                             blendShapes: blendShapes)
    }

    func test_neutralFrontalPose_passesAllGates() {
        XCTAssertTrue(violations().isEmpty)
    }

    // MARK: Pose gates

    func test_yawWindow_boundaries() {
        XCTAssertTrue(violations(pose: pose(yaw: 5)).isEmpty, "just inside the ±5° window")
        XCTAssertEqual(violations(pose: pose(yaw: 5.5)), [.yawOutOfWindow])
    }

    func test_obliquePoses_useTheirTargetYaw() {
        XCTAssertTrue(violations(target: .obliqueL, pose: pose(yaw: -30)).isEmpty)
        XCTAssertTrue(violations(target: .obliqueR, pose: pose(yaw: 30)).isEmpty)
        // Frontal yaw is out of window for an oblique target.
        XCTAssertEqual(violations(target: .obliqueL, pose: pose(yaw: 0)), [.yawOutOfWindow])
        // A level check must NOT flag the intentional 30° turn as a problem.
        XCTAssertFalse(violations(target: .obliqueR, pose: pose(yaw: 30)).contains(.pitchTilted))
        XCTAssertFalse(violations(target: .obliqueR, pose: pose(yaw: 30)).contains(.rollTilted))
    }

    func test_pitchGate_boundaries() {
        XCTAssertTrue(violations(pose: pose(pitch: 10)).isEmpty, "at tolerance passes")
        XCTAssertEqual(violations(pose: pose(pitch: -10.5)), [.pitchTilted])
    }

    func test_rollGate_boundaries() {
        XCTAssertTrue(violations(pose: pose(roll: 7)).isEmpty)
        XCTAssertEqual(violations(pose: pose(roll: 7.5)), [.rollTilted])
        XCTAssertEqual(violations(pose: pose(roll: -8)), [.rollTilted])
    }

    // MARK: Expression gates

    func test_jawOpen_boundary() {
        XCTAssertTrue(violations(blendShapes: ["jawOpen": 0.15]).isEmpty, "at threshold passes")
        XCTAssertEqual(violations(blendShapes: ["jawOpen": 0.16]), [.jawOpen])
    }

    func test_smile_eitherSideTrips() {
        XCTAssertEqual(violations(blendShapes: ["mouthSmile_L": 0.25]), [.smiling])
        XCTAssertEqual(violations(blendShapes: ["mouthSmile_R": 0.25]), [.smiling])
        XCTAssertTrue(violations(blendShapes: ["mouthSmile_L": 0.19, "mouthSmile_R": 0.19]).isEmpty)
    }

    func test_browRaised_boundary() {
        XCTAssertTrue(violations(blendShapes: ["browInnerUp": 0.25]).isEmpty)
        XCTAssertEqual(violations(blendShapes: ["browInnerUp": 0.3]), [.browRaised])
    }

    func test_eyesClosed_boundary() {
        XCTAssertTrue(violations(blendShapes: ["eyeBlink_L": 0.35, "eyeBlink_R": 0.35]).isEmpty,
                      "naturally narrow eyes must not trip the gate")
        XCTAssertEqual(violations(blendShapes: ["eyeBlink_R": 0.5]), [.eyesClosed])
    }

    // MARK: Ordering + ratio

    func test_ordering_isPoseFirstThenExpression() {
        let all = violations(pose: pose(pitch: 20, yaw: 20, roll: 20),
                             blendShapes: ["jawOpen": 1, "mouthSmile_L": 1,
                                           "browInnerUp": 1, "eyeBlink_L": 1])
        XCTAssertEqual(all, [.yawOutOfWindow, .pitchTilted, .rollTilted,
                             .jawOpen, .smiling, .browRaised, .eyesClosed])
    }

    func test_expressionRatio() {
        XCTAssertEqual(CaptureGate.expressionRatio(blendShapes: [:]), 0)
        // jawOpen at exactly its threshold → ratio 1.
        XCTAssertEqual(CaptureGate.expressionRatio(blendShapes: ["jawOpen": 0.15]), 1.0,
                       accuracy: 1e-6)
        // Worst ratio wins: smile at 2× dominates jaw at 0.5×.
        let ratio = CaptureGate.expressionRatio(blendShapes: ["jawOpen": 0.075,
                                                              "mouthSmile_R": 0.40])
        XCTAssertEqual(ratio, 2.0, accuracy: 1e-6)
    }
}
