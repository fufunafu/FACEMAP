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
    /// Optional so SwiftData lightweight migration from pre-`notes` stores succeeds.
    /// Treat `nil` and `""` interchangeably at call sites.
    var notes: String?

    /// Oblique-left capture (patient turned to their right). Optional so single-pose
    /// records from before multi-pose capture continue to load. The frontal pose lives
    /// in `capturedFaceJSON`; this and `obliqueRCapturedFaceJSON` are the two side poses.
    @Attribute(.externalStorage) var obliqueLCapturedFaceJSON: Data?
    /// Oblique-right capture (patient turned to their left).
    @Attribute(.externalStorage) var obliqueRCapturedFaceJSON: Data?

    /// Clinical photos (portrait JPEG) captured alongside each mesh pose. All optional —
    /// pre-photo records and mesh-only captures continue to load via lightweight migration.
    @Attribute(.externalStorage) var frontalPhotoJPEG: Data?
    @Attribute(.externalStorage) var obliqueLPhotoJPEG: Data?
    @Attribute(.externalStorage) var obliqueRPhotoJPEG: Data?

    init(id: UUID = UUID(),
         label: String,
         createdAt: Date = Date(),
         capturedFace: CapturedFace,
         metricResults: [MetricResult],
         patient: Patient? = nil,
         notes: String? = nil,
         annotations: [AnnotationPin] = [],
         obliqueL: CapturedFace? = nil,
         obliqueR: CapturedFace? = nil,
         photos: [CapturePose: Data] = [:]) {
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
        self.obliqueLCapturedFaceJSON = obliqueL.flatMap { try? JSONEncoder().encode($0) }
        self.obliqueRCapturedFaceJSON = obliqueR.flatMap { try? JSONEncoder().encode($0) }
        self.frontalPhotoJPEG = photos[.frontal]
        self.obliqueLPhotoJPEG = photos[.obliqueL]
        self.obliqueRPhotoJPEG = photos[.obliqueR]
    }

    /// Clinical photo for a pose, if one was stored.
    func photo(for pose: CapturePose) -> Data? {
        switch pose {
        case .frontal:  return frontalPhotoJPEG
        case .obliqueL: return obliqueLPhotoJPEG
        case .obliqueR: return obliqueRPhotoJPEG
        }
    }

    /// All stored photos keyed by pose.
    var photosByPose: [CapturePose: Data] {
        var out: [CapturePose: Data] = [:]
        out[.frontal] = frontalPhotoJPEG
        out[.obliqueL] = obliqueLPhotoJPEG
        out[.obliqueR] = obliqueRPhotoJPEG
        return out
    }

    var capturedFace: CapturedFace? {
        try? JSONDecoder().decode(CapturedFace.self, from: capturedFaceJSON)
    }

    var obliqueLCapturedFace: CapturedFace? {
        guard let data = obliqueLCapturedFaceJSON else { return nil }
        return try? JSONDecoder().decode(CapturedFace.self, from: data)
    }

    var obliqueRCapturedFace: CapturedFace? {
        guard let data = obliqueRCapturedFaceJSON else { return nil }
        return try? JSONDecoder().decode(CapturedFace.self, from: data)
    }

    /// Reassemble the original `MultiPoseCapture` from the three stored faces.
    /// Returns nil when the frontal pose can't be decoded.
    var multiPoseCapture: MultiPoseCapture? {
        guard let frontal = capturedFace else { return nil }
        return MultiPoseCapture(
            frontal: frontal,
            obliqueL: obliqueLCapturedFace,
            obliqueR: obliqueRCapturedFace,
            photos: photosByPose
        )
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
