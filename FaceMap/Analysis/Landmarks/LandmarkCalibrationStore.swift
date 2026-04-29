import Foundation

/// Persists practitioner-calibrated landmark vertex indices in UserDefaults so they survive
/// across launches and override the placeholder values in `FaceLandmarkIndices.defaultVertexIndex`.
///
/// Used by `FaceLandmarkIndices.vertexIndex` (computed) so any code reading landmark indices
/// transparently picks up the user's calibration without changing the call site.
final class LandmarkCalibrationStore {
    static let shared = LandmarkCalibrationStore()

    private let key = "landmarkVertexIndices.v1"
    private let defaults: UserDefaults
    private var cachedEffective: [AnatomicalLandmark: Int]?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Calibrated indices only — empty until the user has run calibration.
    func calibrated() -> [AnatomicalLandmark: Int] {
        guard let data = defaults.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var out: [AnatomicalLandmark: Int] = [:]
        for (k, v) in dict {
            if let lm = AnatomicalLandmark(rawValue: k) { out[lm] = v }
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
    func save(_ indices: [AnatomicalLandmark: Int]) {
        let dict = Dictionary(uniqueKeysWithValues: indices.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: key)
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

    var calibratedCount: Int { calibrated().count }
}
