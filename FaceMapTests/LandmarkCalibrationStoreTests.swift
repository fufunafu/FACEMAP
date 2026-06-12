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
        store.save([.glabella: 1123])

        let effective = store.effective()
        // The override takes precedence.
        XCTAssertEqual(effective[.glabella], 1123)
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

/// Data-integrity hardening: index validation, corrupt-payload tolerance, and the
/// versioned persistence envelope (with legacy-format reads).
final class LandmarkCalibrationStoreHardeningTests: XCTestCase {
    private let key = "landmarkVertexIndices.v1"
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "facemap.calibration.hardening.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: Index validation

    func test_save_dropsNegativeAndOutOfRangeIndices() {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save([.glabella: -1, .menton: 1220, .nasion: 99_999, .pronasale: 0, .stomion: 1219])

        let out = store.calibrated()
        XCTAssertNil(out[.glabella], "negative index must be rejected")
        XCTAssertNil(out[.menton], "index == vertex count must be rejected")
        XCTAssertNil(out[.nasion], "huge index must be rejected")
        XCTAssertEqual(out[.pronasale], 0, "lower boundary is valid")
        XCTAssertEqual(out[.stomion], 1219, "upper boundary (count - 1) is valid")
    }

    func test_read_dropsOutOfRangeIndicesFromPersistedData() throws {
        // Legacy payload written by a hypothetical buggy build: one valid, two invalid.
        let legacy = try JSONEncoder().encode(["glabella": -7, "menton": 5_000, "nasion": 42])
        defaults.set(legacy, forKey: key)

        let store = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertEqual(store.calibrated(), [.nasion: 42])
    }

    // MARK: Corrupt payloads

    func test_corruptData_underKey_degradesToDefaults() {
        defaults.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: key)

        let store = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertFalse(store.hasAnyCalibration)
        XCTAssertEqual(store.effective(), FaceLandmarkIndices.defaultVertexIndex)
    }

    func test_structurallyValidButWrongJSON_degradesToDefaults() {
        defaults.set(Data(#"{"glabella":"not an int"}"#.utf8), forKey: key)

        let store = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertEqual(store.effective(), FaceLandmarkIndices.defaultVertexIndex)
    }

    // MARK: Versioned envelope

    func test_save_writesVersionedEnvelope_andRoundTrips() throws {
        let store = LandmarkCalibrationStore(defaults: defaults)
        store.save([.glabella: 100, .menton: 200])

        let raw = try XCTUnwrap(defaults.data(forKey: key))
        let obj = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: raw) as? [String: Any]
        )
        XCTAssertNotNil(obj["version"] as? Int)
        XCTAssertGreaterThanOrEqual(obj["version"] as? Int ?? 0, 2)
        XCTAssertNotNil(obj["savedAt"])
        XCTAssertNotNil(obj["deviceModel"] as? String)
        XCTAssertEqual(obj["vertexCount"] as? Int, FaceLandmarkIndices.arkitVertexCount)
        XCTAssertNotNil(obj["entries"] as? [String: Int])

        // A fresh store reads the envelope back.
        let store2 = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertEqual(store2.calibrated(), [.glabella: 100, .menton: 200])
    }

    func test_legacyUnversionedFormat_isStillRead() throws {
        let legacy = try JSONEncoder().encode(["glabella": 77, "menton": 88])
        defaults.set(legacy, forKey: key)

        let store = LandmarkCalibrationStore(defaults: defaults)
        XCTAssertEqual(store.calibrated(), [.glabella: 77, .menton: 88])
        XCTAssertEqual(store.effective()[.glabella], 77)
    }

    func test_legacyFormat_isUpgradedToEnvelopeOnNextSave() throws {
        let legacy = try JSONEncoder().encode(["glabella": 77])
        defaults.set(legacy, forKey: key)

        let store = LandmarkCalibrationStore(defaults: defaults)
        store.merge([.menton: 88])

        let raw = try XCTUnwrap(defaults.data(forKey: key))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: raw) as? [String: Any])
        XCTAssertNotNil(obj["version"], "save should upgrade legacy payloads to the envelope")
        XCTAssertEqual(store.calibrated(), [.glabella: 77, .menton: 88])
    }
}
