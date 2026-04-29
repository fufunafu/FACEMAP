import Foundation
import SwiftData

/// A pseudonymous patient. The `code` is free-text (e.g. "P-014") and is the only identifying
/// label kept on-device. No PII fields are added by design — keeping clinical workflow on the
/// planning-aid side of the regulatory line.
@Model
final class Patient {
    @Attribute(.unique) var id: UUID
    /// Free-text code such as "P-014". Practitioner's choice; no validation.
    var code: String
    var createdAt: Date
    /// Soft-delete timestamp. Archived patients are hidden from the main list.
    var archivedAt: Date?
    /// Optional free-text notes scoped to the patient (not the visit).
    var notes: String

    /// Inverse relationship — visits captured under this patient.
    /// On patient delete, cascade visits.
    @Relationship(deleteRule: .cascade, inverse: \PatientCase.patient)
    var cases: [PatientCase] = []

    init(id: UUID = UUID(),
         code: String,
         createdAt: Date = Date(),
         archivedAt: Date? = nil,
         notes: String = "") {
        self.id = id
        self.code = code
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        self.notes = notes
    }

    /// Visits sorted newest-first.
    var sortedCases: [PatientCase] {
        cases.sorted { $0.createdAt > $1.createdAt }
    }
}

extension Patient {
    /// Reserved code used by the migration to bucket pre-v0.2 cases.
    static let unassignedCode = "Unassigned"
}
