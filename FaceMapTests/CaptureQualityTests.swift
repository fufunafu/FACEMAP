import XCTest
@testable import FaceMap

final class CaptureQualityTests: XCTestCase {

    private func quality(framesAveraged: Int = 10,
                         meanJitterMM: Float = 0,
                         maxJitterMM: Float = 0,
                         yawErrorDegrees: Float = 0,
                         pitchDegrees: Float = 0,
                         rollDegrees: Float = 0,
                         expressionMax: Float = 0,
                         gateViolations: [String] = []) -> CaptureQuality {
        CaptureQuality.compute(framesAveraged: framesAveraged,
                               meanJitterMM: meanJitterMM,
                               maxJitterMM: maxJitterMM,
                               yawErrorDegrees: yawErrorDegrees,
                               pitchDegrees: pitchDegrees,
                               rollDegrees: rollDegrees,
                               expressionMax: expressionMax,
                               gateViolations: gateViolations)
    }

    func test_perfectCapture_scoresOne() {
        let q = quality()
        XCTAssertEqual(q.composite, 1.0, accuracy: 1e-6)
        XCTAssertEqual(q.band, .good)
    }

    func test_knownSubscores_compose() {
        // s_jitter = 1 - 0.25/0.5 = 0.5; s_pose = 1 - 5/15 = 2/3 (yaw dominates);
        // s_expr = 1 - 1.0/2 = 0.5; s_frames = 0.5.
        let q = quality(framesAveraged: 5,
                        meanJitterMM: 0.25,
                        yawErrorDegrees: 5,
                        expressionMax: 1.0)
        let expected: Float = 0.35 * 0.5 + 0.30 * (2.0 / 3.0) + 0.25 * 0.5 + 0.10 * 0.5
        XCTAssertEqual(q.composite, expected, accuracy: 1e-5)
    }

    func test_poseSubscore_takesWorstAxis() {
        // pitch 30° zeroes s_pose regardless of yaw/roll being perfect.
        let q = quality(pitchDegrees: 30)
        let qYawOnly = quality(yawErrorDegrees: 15)
        XCTAssertEqual(q.composite, qYawOnly.composite, accuracy: 1e-6)
    }

    func test_subscoresClampAtZero_notNegative() {
        // Far past every limit: composite must stay >= 0 (only s_frames contributes).
        let q = quality(framesAveraged: 10,
                        meanJitterMM: 5,
                        yawErrorDegrees: 90,
                        expressionMax: 10)
        XCTAssertEqual(q.composite, 0.10, accuracy: 1e-6)
        XCTAssertGreaterThanOrEqual(q.composite, 0)
    }

    func test_bandEdges() {
        XCTAssertEqual(CaptureQuality.compute(framesAveraged: 10, meanJitterMM: 0, maxJitterMM: 0,
                                              yawErrorDegrees: 0, pitchDegrees: 0, rollDegrees: 0,
                                              expressionMax: 0, gateViolations: []).band, .good)
        // Composite exactly 0.80 → good (>= boundary).
        // s_jitter drop of 0.2/0.35 → need meanJitter = 0.5 * (0.2/0.35)... simpler:
        // drive expression only: composite = 1 - 0.25*(expressionMax/2). 0.80 → expressionMax = 1.6.
        let atGoodEdge = quality(expressionMax: 1.6)
        XCTAssertEqual(atGoodEdge.composite, 0.80, accuracy: 1e-6)
        XCTAssertEqual(atGoodEdge.band, .good)
        // Just below 0.60 → poor. composite = 1 - 0.25*(e/2) - ... use jitter too.
        let poor = quality(meanJitterMM: 0.5, expressionMax: 0.5)
        // s_jitter = 0 → composite = 0.30 + 0.25*0.75 + 0.10 = 0.5875 < 0.60
        XCTAssertEqual(poor.band, .poor)
        // Between 0.60 and 0.80 → fair. expressionMax 2 → s_expr 0 → composite 0.75.
        let fair = quality(expressionMax: 2)
        XCTAssertEqual(fair.composite, 0.75, accuracy: 1e-6)
        XCTAssertEqual(fair.band, .fair)
    }

    func test_monotonicInJitter() {
        var previous: Float = 2
        for jitter in stride(from: Float(0), through: 0.6, by: 0.1) {
            let c = quality(meanJitterMM: jitter).composite
            XCTAssertLessThanOrEqual(c, previous)
            previous = c
        }
    }

    func test_codableRoundTrip() throws {
        let q = quality(framesAveraged: 7, meanJitterMM: 0.1, maxJitterMM: 0.3,
                        yawErrorDegrees: 2, pitchDegrees: -4, rollDegrees: 1,
                        expressionMax: 0.4, gateViolations: ["smiling"])
        let data = try JSONEncoder().encode(q)
        let decoded = try JSONDecoder().decode(CaptureQuality.self, from: data)
        XCTAssertEqual(decoded, q)
    }
}
