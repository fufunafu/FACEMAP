import Combine
import XCTest
@testable import FaceMap

/// The capture calibration gate: full-calibration predicate, live lifting via the
/// store's ObservableObject conformance, and the session-only evaluation override.
final class CalibrationGateTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "facemap.calibrationgate.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func fullCalibration(excluding excluded: AnatomicalLandmark? = nil) -> [AnatomicalLandmark: Int] {
        var out: [AnatomicalLandmark: Int] = [:]
        for (i, landmark) in AnatomicalLandmark.allCases.enumerated() where landmark != excluded {
            out[landmark] = i   // any in-range index will do
        }
        return out
    }

    // MARK: isFullyCalibrated boundary

    func test_isFullyCalibrated_falseWhenEmpty() {
        XCTAssertFalse(LandmarkCalibrationStore(defaults: defaults).isFullyCalibrated)
    }

    func test_isFullyCalibrated_falseAtAllButOne() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        let missing = AnatomicalLandmark.allCases.last!
        store.save(fullCalibration(excluding: missing))
        XCTAssertEqual(store.calibratedCount, AnatomicalLandmark.allCases.count - 1)
        XCTAssertFalse(store.isFullyCalibrated)
    }

    func test_isFullyCalibrated_trueAtAll() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save(fullCalibration())
        XCTAssertTrue(store.isFullyCalibrated)
    }

    /// The calibration walkthrough must cover exactly the landmarks the gate
    /// requires — a landmark missing from `calibrationOrder` would make the gate
    /// impossible to satisfy through the UI.
    func test_calibrationOrder_coversAllLandmarks() {
        XCTAssertEqual(Set(AnatomicalLandmark.calibrationOrder), Set(AnatomicalLandmark.allCases))
        XCTAssertEqual(AnatomicalLandmark.calibrationOrder.count, AnatomicalLandmark.allCases.count,
                       "no duplicates in the walkthrough order")
    }

    // MARK: Live lifting (ObservableObject)

    func test_objectWillChange_firesOnSaveMergeClear() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        var fired = 0
        let subscription = store.objectWillChange.sink { fired += 1 }
        defer { subscription.cancel() }

        store.save([.glabella: 1])
        XCTAssertEqual(fired, 1, "save publishes")
        store.merge([.menton: 2])
        XCTAssertEqual(fired, 2, "merge funnels through save")
        store.clear()
        XCTAssertEqual(fired, 3, "clear publishes")
    }

    // MARK: Session override

    func test_gateSession_defaultsToNoOverride() {
        XCTAssertFalse(CalibrationGateSession().evaluationOverrideGranted,
                       "override must start false every launch — it is never persisted")
    }

    func test_gatePredicate_truthTable() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        let session = CalibrationGateSession()
        func gateOpen() -> Bool { store.isFullyCalibrated || session.evaluationOverrideGranted }

        XCTAssertFalse(gateOpen(), "uncalibrated + no override → blocked")
        session.evaluationOverrideGranted = true
        XCTAssertTrue(gateOpen(), "override opens the gate for the session")
        session.evaluationOverrideGranted = false
        store.save(fullCalibration())
        XCTAssertTrue(gateOpen(), "full calibration opens the gate permanently")
    }
}
