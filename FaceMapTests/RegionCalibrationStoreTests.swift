import XCTest
@testable import FaceMap

final class RegionCalibrationStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "facemap.region.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_calibrated_isEmptyByDefault() {
        let store = RegionCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertFalse(store.hasAnyCalibration)
    }

    func test_save_and_calibrated_roundTrip() {
        let store = RegionCalibrationStore(defaults: defaults)
        let input: [FacialRegion: [Int]] = [
            .midfaceL: [10, 20, 30],
            .chin:     [100, 110]
        ]
        store.save(input)

        let store2 = RegionCalibrationStore(defaults: defaults)
        let out = store2.calibrated()
        XCTAssertEqual(out[.midfaceL], [10, 20, 30])
        XCTAssertEqual(out[.chin], [100, 110])
        XCTAssertEqual(out.count, 2)
    }

    func test_effective_mergesOverDefaults() {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [999, 1000, 1001]])

        let effective = store.effective()
        // Override takes precedence
        XCTAssertEqual(effective[.chin], [999, 1000, 1001])
        // Un-overridden region falls back to placeholder default
        XCTAssertEqual(effective[.forehead], FaceLandmarkIndices.defaultRegionVertices[.forehead])
        // Effective covers every region the placeholders cover
        XCTAssertEqual(effective.count, FaceLandmarkIndices.defaultRegionVertices.count)
    }

    func test_merge_clearsRegionWithEmptyArray() {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [1, 2, 3], .midfaceL: [4, 5]])
        // Empty array clears that region, restoring the default in `effective()`.
        store.merge([.chin: []])
        let calib = store.calibrated()
        XCTAssertNil(calib[.chin])
        XCTAssertEqual(calib[.midfaceL], [4, 5])
        XCTAssertEqual(store.effective()[.chin], FaceLandmarkIndices.defaultRegionVertices[.chin])
    }

    func test_clear_removesAll() {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [1, 2]])
        XCTAssertTrue(store.hasAnyCalibration)
        store.clear()
        XCTAssertFalse(store.hasAnyCalibration)
    }
}
