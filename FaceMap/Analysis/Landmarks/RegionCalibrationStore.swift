import Foundation

/// Persists practitioner-painted region vertex sets in UserDefaults so the heatmap,
/// asymmetry metric, and surface-displacement metric measure the right anatomy.
///
/// Mirrors `LandmarkCalibrationStore`'s shape (single-instance UserDefaults wrapper +
/// computed merge with defaults), keeping the calibration system uniform.
final class RegionCalibrationStore {
    static let shared = RegionCalibrationStore()

    private let key = "regionVertexIndices.v1"
    private let defaults: UserDefaults
    private var cachedEffective: [FacialRegion: [Int]]?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Calibrated overrides only — empty until the user has run region calibration.
    func calibrated() -> [FacialRegion: [Int]] {
        guard let data = defaults.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        var out: [FacialRegion: [Int]] = [:]
        for (k, v) in dict {
            if let r = FacialRegion(rawValue: k) { out[r] = v }
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
    func save(_ regions: [FacialRegion: [Int]]) {
        let dict = Dictionary(uniqueKeysWithValues: regions.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: key)
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
}
