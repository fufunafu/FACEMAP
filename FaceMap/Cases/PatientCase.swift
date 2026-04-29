import Foundation
import SwiftData

/// One captured-and-analyzed face. The label is free-text and can be a code (e.g. "P-014 V2")
/// to keep the on-device store free of identifying information by default.
@Model
final class PatientCase {
    @Attribute(.unique) var id: UUID
    var label: String
    var createdAt: Date
    /// Raw mesh data, encoded JSON of `CapturedFace`. Storing the raw mesh means future metrics
    /// can re-analyze old captures without recapture.
    @Attribute(.externalStorage) var capturedFaceJSON: Data
    /// Metric results at the time of capture, encoded JSON of `[MetricResult]`.
    var metricResultsJSON: Data

    init(id: UUID = UUID(),
         label: String,
         createdAt: Date = Date(),
         capturedFace: CapturedFace,
         metricResults: [MetricResult]) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
        self.capturedFaceJSON = (try? JSONEncoder().encode(capturedFace)) ?? Data()
        self.metricResultsJSON = (try? JSONEncoder().encode(metricResults)) ?? Data()
    }

    var capturedFace: CapturedFace? {
        try? JSONDecoder().decode(CapturedFace.self, from: capturedFaceJSON)
    }

    var metricResults: [MetricResult] {
        (try? JSONDecoder().decode([MetricResult].self, from: metricResultsJSON)) ?? []
    }

    func updateMetricResults(_ results: [MetricResult]) {
        self.metricResultsJSON = (try? JSONEncoder().encode(results)) ?? Data()
    }
}
