import Foundation
import SwiftData

/// One captured-and-analyzed face — a single visit. The label is free-text (e.g. "Visit 2")
/// and pairs with a `Patient` for grouping. No PII fields are added.
@Model
final class PatientCase {
    @Attribute(.unique) var id: UUID
    var label: String
    var createdAt: Date

    /// Owning patient. Optional only so SwiftData migrations from pre-v0.2 stores succeed;
    /// the migration in `CaseStore.bootstrap` rebinds orphans to an "Unassigned" patient.
    var patient: Patient?

    /// Raw mesh data, encoded JSON of `CapturedFace`. Storing the raw mesh means future metrics
    /// can re-analyze old captures without recapture.
    @Attribute(.externalStorage) var capturedFaceJSON: Data
    /// Metric results at the time of capture, encoded JSON of `[MetricResult]`.
    var metricResultsJSON: Data
    /// Annotation pins dropped on the mesh in Annotate mode. Encoded JSON of `[AnnotationPin]`.
    var annotationsJSON: Data?
    /// Free-text clinician notes scoped to the visit.
    var notes: String

    init(id: UUID = UUID(),
         label: String,
         createdAt: Date = Date(),
         capturedFace: CapturedFace,
         metricResults: [MetricResult],
         patient: Patient? = nil,
         notes: String = "",
         annotations: [AnnotationPin] = []) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
        self.patient = patient
        self.capturedFaceJSON = (try? JSONEncoder().encode(capturedFace)) ?? Data()
        self.metricResultsJSON = (try? JSONEncoder().encode(metricResults)) ?? Data()
        self.annotationsJSON = annotations.isEmpty
            ? nil
            : (try? JSONEncoder().encode(annotations))
        self.notes = notes
    }

    var capturedFace: CapturedFace? {
        try? JSONDecoder().decode(CapturedFace.self, from: capturedFaceJSON)
    }

    var metricResults: [MetricResult] {
        (try? JSONDecoder().decode([MetricResult].self, from: metricResultsJSON)) ?? []
    }

    var annotations: [AnnotationPin] {
        guard let data = annotationsJSON else { return [] }
        return (try? JSONDecoder().decode([AnnotationPin].self, from: data)) ?? []
    }

    func updateMetricResults(_ results: [MetricResult]) {
        self.metricResultsJSON = (try? JSONEncoder().encode(results)) ?? Data()
    }

    func updateAnnotations(_ pins: [AnnotationPin]) {
        self.annotationsJSON = pins.isEmpty
            ? nil
            : (try? JSONEncoder().encode(pins))
    }
}
