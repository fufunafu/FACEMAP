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

/// Data-integrity hardening: index validation, corrupt-payload tolerance, and the
/// versioned persistence envelope (with legacy-format reads).
final class RegionCalibrationStoreHardeningTests: XCTestCase {
    private let key = "regionVertexIndices.v1"
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "facemap.region.hardening.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: Index validation

    func test_save_filtersNegativeAndOutOfRangeIndices() {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [-5, 10, 1220, 99_999, 0, 1219]])

        // Order is preserved; only the in-range indices survive.
        XCTAssertEqual(store.calibrated()[.chin], [10, 0, 1219])
    }

    func test_save_dropsRegionWhoseIndicesAreAllInvalid() {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [-1, 5_000], .midfaceL: [3, 4]])

        let out = store.calibrated()
        XCTAssertNil(out[.chin], "a region with no surviving valid index reads back as uncalibrated")
        XCTAssertEqual(out[.midfaceL], [3, 4])
        // effective() falls back to the placeholder default for the dropped region.
        XCTAssertEqual(store.effective()[.chin], FaceLandmarkIndices.defaultRegionVertices[.chin])
    }

    func test_read_filtersOutOfRangeIndicesFromPersistedData() throws {
        let legacy = try JSONEncoder().encode(["chin": [-2, 7, 4_000], "midfaceL": [9_999]])
        defaults.set(legacy, forKey: key)

        let store = RegionCalibrationStore(defaults: defaults)
        let out = store.calibrated()
        XCTAssertEqual(out[.chin], [7])
        XCTAssertNil(out[.midfaceL])
    }

    // MARK: Corrupt payloads

    func test_corruptData_underKey_degradesToDefaults() {
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: key)

        let store = RegionCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertFalse(store.hasAnyCalibration)
        XCTAssertEqual(store.effective(), FaceLandmarkIndices.defaultRegionVertices)
    }

    func test_structurallyValidButWrongJSON_degradesToDefaults() {
        defaults.set(Data(#"{"chin":"not an array"}"#.utf8), forKey: key)

        let store = RegionCalibrationStore(defaults: defaults)
        XCTAssertTrue(store.calibrated().isEmpty)
        XCTAssertEqual(store.effective(), FaceLandmarkIndices.defaultRegionVertices)
    }

    // MARK: Versioned envelope

    func test_save_writesVersionedEnvelope_andRoundTrips() throws {
        let store = RegionCalibrationStore(defaults: defaults)
        store.save([.chin: [100, 200], .midfaceL: [5]])

        let raw = try XCTUnwrap(defaults.data(forKey: key))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: raw) as? [String: Any])
        XCTAssertNotNil(obj["version"] as? Int)
        XCTAssertGreaterThanOrEqual(obj["version"] as? Int ?? 0, 2)
        XCTAssertNotNil(obj["savedAt"])
        XCTAssertNotNil(obj["deviceModel"] as? String)
        XCTAssertEqual(obj["vertexCount"] as? Int, FaceLandmarkIndices.arkitVertexCount)
        XCTAssertNotNil(obj["entries"] as? [String: [Int]])

        let store2 = RegionCalibrationStore(defaults: defaults)
        XCTAssertEqual(store2.calibrated(), [.chin: [100, 200], .midfaceL: [5]])
    }

    func test_legacyUnversionedFormat_isStillRead() throws {
        let legacy = try JSONEncoder().encode(["chin": [11, 12], "jawlineL": [13]])
        defaults.set(legacy, forKey: key)

        let store = RegionCalibrationStore(defaults: defaults)
        XCTAssertEqual(store.calibrated(), [.chin: [11, 12], .jawlineL: [13]])
        XCTAssertEqual(store.effective()[.chin], [11, 12])
    }

    func test_legacyFormat_isUpgradedToEnvelopeOnNextSave() throws {
        let legacy = try JSONEncoder().encode(["chin": [11]])
        defaults.set(legacy, forKey: key)

        let store = RegionCalibrationStore(defaults: defaults)
        store.merge([.midfaceL: [22]])

        let raw = try XCTUnwrap(defaults.data(forKey: key))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: raw) as? [String: Any])
        XCTAssertNotNil(obj["version"], "save should upgrade legacy payloads to the envelope")
        XCTAssertEqual(store.calibrated(), [.chin: [11], .midfaceL: [22]])
    }
}
