import Foundation
import os

/// Persists practitioner-calibrated landmark vertex indices in UserDefaults so they survive
/// across launches and override the placeholder values in `FaceLandmarkIndices.defaultVertexIndex`.
///
/// Used by `FaceLandmarkIndices.vertexIndex` (computed) so any code reading landmark indices
/// transparently picks up the user's calibration without changing the call site.
///
/// Persistence format: a versioned envelope (`{version, savedAt, deviceModel, vertexCount,
/// entries}`). The original unversioned `[String: Int]` payload is still read for backward
/// compatibility and upgraded to the envelope on the next `save(_:)`. Indices are validated
/// to `0..<FaceLandmarkIndices.arkitVertexCount` on both read and write — invalid entries
/// are dropped (and logged) rather than allowed to crash mesh code downstream.
final class LandmarkCalibrationStore {
    static let shared = LandmarkCalibrationStore()

    private static let logger = Logger(subsystem: "com.fuanne.facemap",
                                       category: "LandmarkCalibrationStore")

    private let key = "landmarkVertexIndices.v1"
    private let defaults: UserDefaults
    private var cachedEffective: [AnatomicalLandmark: Int]?

    /// Versioned wrapper around the persisted entries. `vertexCount` records the mesh
    /// topology the calibration was made against; `deviceModel` aids forensics when a
    /// calibration turns out to be bad.
    private struct Envelope: Codable {
        var version: Int
        var savedAt: Date
        var deviceModel: String
        var vertexCount: Int
        var entries: [String: Int]
    }

    private static let currentVersion = 2

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Calibrated indices only — empty until the user has run calibration.
    /// Reads both the current envelope format and the legacy unversioned dictionary.
    func calibrated() -> [AnatomicalLandmark: Int] {
        guard let data = defaults.data(forKey: key) else { return [:] }

        let dict: [String: Int]
        do {
            dict = try JSONDecoder().decode(Envelope.self, from: data).entries
        } catch {
            do {
                // Legacy pre-envelope format: bare [String: Int]. Upgraded to the
                // envelope on the next save.
                dict = try JSONDecoder().decode([String: Int].self, from: data)
            } catch {
                Self.logger.error("Failed to decode landmark calibration (\(data.count) bytes) as envelope or legacy format: \(String(describing: error), privacy: .public). Falling back to defaults.")
                return [:]
            }
        }

        var out: [AnatomicalLandmark: Int] = [:]
        for (k, v) in dict {
            guard let lm = AnatomicalLandmark(rawValue: k) else { continue }
            guard (0..<FaceLandmarkIndices.arkitVertexCount).contains(v) else {
                Self.logger.error("Dropping calibrated landmark \(k, privacy: .public): index \(v) outside 0..<\(FaceLandmarkIndices.arkitVertexCount)")
                continue
            }
            out[lm] = v
        }
        return out
    }

    /// Calibrated overrides merged on top of `FaceLandmarkIndices.defaultVertexIndex`.
    /// This is what metrics actually consume.
    func effective() -> [AnatomicalLandmark: Int] {
        if let c = cachedEffective { return c }
        var merged = FaceLandmarkIndices.defaultVertexIndex
        for (k, v) in calibrated() { merged[k] = v }
        cachedEffective = merged
        return merged
    }

    /// Replace the entire calibration with the given map. Use `merge(_:)` to update incrementally.
    /// Out-of-range indices are dropped (and logged), never persisted.
    func save(_ indices: [AnatomicalLandmark: Int]) {
        var entries: [String: Int] = [:]
        for (k, v) in indices {
            guard (0..<FaceLandmarkIndices.arkitVertexCount).contains(v) else {
                Self.logger.error("Refusing to save landmark \(k.rawValue, privacy: .public): index \(v) outside 0..<\(FaceLandmarkIndices.arkitVertexCount)")
                continue
            }
            entries[k.rawValue] = v
        }
        let envelope = Envelope(
            version: Self.currentVersion,
            savedAt: Date(),
            deviceModel: Self.deviceModel(),
            vertexCount: FaceLandmarkIndices.arkitVertexCount,
            entries: entries
        )
        do {
            let data = try JSONEncoder().encode(envelope)
            defaults.set(data, forKey: key)
        } catch {
            Self.logger.error("Failed to encode landmark calibration envelope: \(String(describing: error), privacy: .public). Calibration NOT saved.")
        }
        cachedEffective = nil
    }

    /// Merge `partial` into the existing calibration (only the supplied keys are updated).
    func merge(_ partial: [AnatomicalLandmark: Int]) {
        var existing = calibrated()
        for (k, v) in partial { existing[k] = v }
        save(existing)
    }

    func clear() {
        defaults.removeObject(forKey: key)
        cachedEffective = nil
    }

    var hasAnyCalibration: Bool { !calibrated().isEmpty }

    /// True once every anatomical landmark has a practitioner-calibrated index.
    /// Until then metric outputs rest on the placeholder indices and the UI/PDF
    /// show the uncalibrated warning.
    var isFullyCalibrated: Bool {
        let saved = calibrated()
        return AnatomicalLandmark.allCases.allSatisfy { saved[$0] != nil }
    }

    var calibratedCount: Int { calibrated().count }

    /// Hardware model identifier (e.g. "iPhone16,1"), recorded in the envelope for forensics.
    private static func deviceModel() -> String {
        var sys = utsname()
        uname(&sys)
        return withUnsafePointer(to: &sys.machine.0) { String(cString: $0) }
    }
}
