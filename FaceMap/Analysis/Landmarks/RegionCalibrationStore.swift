import Foundation
import os

/// Persists practitioner-painted region vertex sets in UserDefaults so the heatmap,
/// asymmetry metric, and surface-displacement metric measure the right anatomy.
///
/// Mirrors `LandmarkCalibrationStore`'s shape (single-instance UserDefaults wrapper +
/// computed merge with defaults), keeping the calibration system uniform — including
/// the versioned envelope (`{version, savedAt, deviceModel, vertexCount, entries}`),
/// backward-compatible reads of the legacy unversioned `[String: [Int]]` payload, and
/// validation of every index to `0..<FaceLandmarkIndices.arkitVertexCount` on both
/// read and write (invalid indices are dropped and logged, never propagated).
final class RegionCalibrationStore {
    static let shared = RegionCalibrationStore()

    private static let logger = Logger(subsystem: "com.fuanne.facemap",
                                       category: "RegionCalibrationStore")

    private let key = "regionVertexIndices.v1"
    private let defaults: UserDefaults
    private var cachedEffective: [FacialRegion: [Int]]?

    /// Versioned wrapper around the persisted entries. `vertexCount` records the mesh
    /// topology the calibration was made against; `deviceModel` aids forensics when a
    /// calibration turns out to be bad.
    private struct Envelope: Codable {
        var version: Int
        var savedAt: Date
        var deviceModel: String
        var vertexCount: Int
        var entries: [String: [Int]]
    }

    private static let currentVersion = 2

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Calibrated overrides only — empty until the user has run region calibration.
    /// Reads both the current envelope format and the legacy unversioned dictionary.
    func calibrated() -> [FacialRegion: [Int]] {
        guard let data = defaults.data(forKey: key) else { return [:] }

        let dict: [String: [Int]]
        do {
            dict = try JSONDecoder().decode(Envelope.self, from: data).entries
        } catch {
            do {
                // Legacy pre-envelope format: bare [String: [Int]]. Upgraded to the
                // envelope on the next save.
                dict = try JSONDecoder().decode([String: [Int]].self, from: data)
            } catch {
                Self.logger.error("Failed to decode region calibration (\(data.count) bytes) as envelope or legacy format: \(String(describing: error), privacy: .public). Falling back to defaults.")
                return [:]
            }
        }

        var out: [FacialRegion: [Int]] = [:]
        for (k, v) in dict {
            guard let r = FacialRegion(rawValue: k) else { continue }
            let valid = validIndices(v, region: k)
            if !valid.isEmpty { out[r] = valid }
        }
        return out
    }

    /// Calibrated overrides merged on top of `FaceLandmarkIndices.defaultRegionVertices`.
    /// This is what the metrics + heatmap actually consume.
    func effective() -> [FacialRegion: [Int]] {
        if let c = cachedEffective { return c }
        var merged = FaceLandmarkIndices.defaultRegionVertices
        for (k, v) in calibrated() where !v.isEmpty { merged[k] = v }
        cachedEffective = merged
        return merged
    }

    /// Replace the entire calibration with the given map. Use `merge(_:)` to update incrementally.
    /// Out-of-range indices are dropped (and logged), never persisted.
    func save(_ regions: [FacialRegion: [Int]]) {
        var entries: [String: [Int]] = [:]
        for (k, v) in regions {
            entries[k.rawValue] = validIndices(v, region: k.rawValue)
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
            Self.logger.error("Failed to encode region calibration envelope: \(String(describing: error), privacy: .public). Calibration NOT saved.")
        }
        cachedEffective = nil
    }

    /// Merge `partial` into the existing calibration (only the supplied keys are updated).
    /// Empty arrays clear that region back to its placeholder default.
    func merge(_ partial: [FacialRegion: [Int]]) {
        var existing = calibrated()
        for (k, v) in partial {
            if v.isEmpty { existing.removeValue(forKey: k) } else { existing[k] = v }
        }
        save(existing)
    }

    func clear() {
        defaults.removeObject(forKey: key)
        cachedEffective = nil
    }

    var hasAnyCalibration: Bool { !calibrated().isEmpty }

    var calibratedCount: Int { calibrated().count }

    /// Keeps only indices inside the ARKit mesh range, logging anything dropped.
    private func validIndices(_ indices: [Int], region: String) -> [Int] {
        let valid = indices.filter { (0..<FaceLandmarkIndices.arkitVertexCount).contains($0) }
        if valid.count != indices.count {
            Self.logger.error("Dropped \(indices.count - valid.count) out-of-range vertex indices (valid range 0..<\(FaceLandmarkIndices.arkitVertexCount)) from region \(region, privacy: .public)")
        }
        return valid
    }

    /// Hardware model identifier (e.g. "iPhone16,1"), recorded in the envelope for forensics.
    private static func deviceModel() -> String {
        var sys = utsname()
        uname(&sys)
        return withUnsafePointer(to: &sys.machine.0) { String(cString: $0) }
    }
}
