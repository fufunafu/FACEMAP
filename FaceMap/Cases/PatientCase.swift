import Foundation
import os
import SwiftData

/// One captured-and-analyzed face — a single visit. The label is free-text (e.g. "Visit 2")
/// and pairs with a `Patient` for grouping. No PII fields are added.
@Model
final class PatientCase {
    private static let logger = Logger(subsystem: "com.fuanne.facemap", category: "PatientCase")

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
        self.capturedFaceJSON = Self.encodeOrEmpty(capturedFace, what: "frontal CapturedFace", caseID: id)
        self.metricResultsJSON = Self.encodeOrEmpty(metricResults, what: "metric results", caseID: id)
        self.annotationsJSON = annotations.isEmpty
            ? nil
            : Self.encodeOrNil(annotations, what: "annotations", caseID: id)
        self.notes = notes
        self.obliqueLCapturedFaceJSON = obliqueL.flatMap {
            Self.encodeOrNil($0, what: "oblique-L CapturedFace", caseID: id)
        }
        self.obliqueRCapturedFaceJSON = obliqueR.flatMap {
            Self.encodeOrNil($0, what: "oblique-R CapturedFace", caseID: id)
        }
        self.frontalPhotoJPEG = photos[.frontal]
        self.obliqueLPhotoJPEG = photos[.obliqueL]
        self.obliqueRPhotoJPEG = photos[.obliqueR]
    }

    // MARK: - Encode/decode seams (logged, never silent)

    /// Encode, falling back to empty `Data` so the (non-optional) column can still be
    /// written — but leave a forensic trail: an empty blob means this record's payload
    /// was lost at save time, not corrupted later.
    private static func encodeOrEmpty<T: Encodable>(_ value: T, what: String, caseID: UUID) -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            logger.error("Failed to encode \(what, privacy: .public) for case \(caseID.uuidString, privacy: .public): \(String(describing: error), privacy: .public). Substituting empty Data — payload is lost.")
            return Data()
        }
    }

    private static func encodeOrNil<T: Encodable>(_ value: T, what: String, caseID: UUID) -> Data? {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            logger.error("Failed to encode \(what, privacy: .public) for case \(caseID.uuidString, privacy: .public): \(String(describing: error), privacy: .public). Storing nil — payload is lost.")
            return nil
        }
    }

    /// Decode, logging (not swallowing) failures so corrupt records are visible in the
    /// unified log. Returns nil so callers keep their existing "Mesh unreadable" paths.
    private func decodeLogged<T: Decodable>(_ type: T.Type, from data: Data, what: String) -> T? {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Self.logger.error("Failed to decode \(what, privacy: .public) for case \(self.id.uuidString, privacy: .public) (\(data.count) bytes): \(String(describing: error), privacy: .public)")
            return nil
        }
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
        decodeLogged(CapturedFace.self, from: capturedFaceJSON, what: "frontal CapturedFace")
    }

    var obliqueLCapturedFace: CapturedFace? {
        guard let data = obliqueLCapturedFaceJSON else { return nil }
        return decodeLogged(CapturedFace.self, from: data, what: "oblique-L CapturedFace")
    }

    var obliqueRCapturedFace: CapturedFace? {
        guard let data = obliqueRCapturedFaceJSON else { return nil }
        return decodeLogged(CapturedFace.self, from: data, what: "oblique-R CapturedFace")
    }

    /// True when at least one stored payload exists but no longer decodes — i.e. the
    /// record is present but (partially) unreadable. Computed on demand from the same
    /// decode paths the accessors use; the UI can adopt this to badge corrupt visits.
    var isCorrupt: Bool {
        if capturedFace == nil { return true }
        if obliqueLCapturedFaceJSON != nil && obliqueLCapturedFace == nil { return true }
        if obliqueRCapturedFaceJSON != nil && obliqueRCapturedFace == nil { return true }
        if decodeLogged([MetricResult].self, from: metricResultsJSON, what: "metric results") == nil {
            return true
        }
        if let data = annotationsJSON,
           decodeLogged([AnnotationPin].self, from: data, what: "annotations") == nil {
            return true
        }
        return false
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
        decodeLogged([MetricResult].self, from: metricResultsJSON, what: "metric results") ?? []
    }

    var annotations: [AnnotationPin] {
        guard let data = annotationsJSON else { return [] }
        return decodeLogged([AnnotationPin].self, from: data, what: "annotations") ?? []
    }

    func updateMetricResults(_ results: [MetricResult]) {
        self.metricResultsJSON = Self.encodeOrEmpty(results, what: "metric results", caseID: id)
    }

    func updateAnnotations(_ pins: [AnnotationPin]) {
        self.annotationsJSON = pins.isEmpty
            ? nil
            : Self.encodeOrNil(pins, what: "annotations", caseID: id)
    }
}
