import XCTest
@testable import FaceMap

final class LandmarkCalibrationStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "facemap.calibration.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_calibrated_isEmptyByDefault() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertFalse(store.hasAnyCalibration)
    }

    func test_save_and_calibrated_roundTrip() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        let input: [AnatomicalLandmark: Int] = [.glabella: 999, .menton: 1010]
        store.save(input)

        // Fresh store reading the same UserDefaults should see the values.
        let store2 = LandmarkCalibrationStore(defaults: defaults)
        let out = store2.calibrated()
        XCTAssertEqual(out[.glabella], 999)
        XCTAssertEqual(out[.menton], 1010)
        XCTAssertEqual(out.count, 2)
    }

    func test_effective_mergesOverDefaults() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save([.glabella: 1234])

        let effective = store.effective()
        // The override takes precedence.
        XCTAssertEqual(effective[.glabella], 1234)
        // An un-overridden landmark falls back to the default.
        XCTAssertEqual(effective[.menton], FaceLandmarkIndices.defaultVertexIndex[.menton])
        // Effective is never smaller than the default set.
        XCTAssertEqual(effective.count, FaceLandmarkIndices.defaultVertexIndex.count)
    }

    func test_merge_addsWithoutDroppingExisting() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save([.glabella: 1])
        store.merge([.menton: 2])
        let out = store.calibrated()
        XCTAssertEqual(out[.glabella], 1)
        XCTAssertEqual(out[.menton], 2)
    }

    func test_clear_removesAll() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save([.glabella: 1, .menton: 2])
        XCTAssertTrue(store.hasAnyCalibration)
        store.clear()
        XCTAssertFalse(store.hasAnyCalibration)
        XCTAssertTrue(store.calibrated().isEmpty)
    }
}
