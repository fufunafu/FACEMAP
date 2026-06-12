import Foundation
import SwiftData
import OSLog

/// Thin facade over a `ModelContext`. Exists so call sites don't depend directly on SwiftData
/// and the cloud-sync layer can be inserted without touching the UI.
final class CaseStore: ObservableObject {
    let context: ModelContext
    private let cloudSync: any CloudSync
    /// Redacting logger — never log codes, labels, or notes (treat them as private).
    private let logger = Logger(subsystem: "com.fuanne.facemap", category: "CaseStore")

    /// Human-readable description of the most recent persistence failure.
    /// Views observe this to drive a "could not save" alert; set to nil on dismiss.
    @Published var lastSaveError: String?

    init(context: ModelContext, cloudSync: any CloudSync = NoopCloudSync()) {
        self.context = context
        self.cloudSync = cloudSync
        bootstrap()
    }

    // MARK: - Persistence funnel

    /// Single choke point for `context.save()`. Runs `mutation`, attempts the save,
    /// logs failures via the redacting logger, and records them in `lastSaveError`.
    @discardableResult
    func persist(_ operation: String, _ mutation: () -> Void = {}) -> Result<Void, Error> {
        mutation()
        do {
            try context.save()
            return .success(())
        } catch {
            logger.error("persist failed (\(operation, privacy: .public)): \(error.localizedDescription, privacy: .public)")
            lastSaveError = "Could not save changes — try again."
            return .failure(error)
        }
    }

    // MARK: - Bootstrap migration

    /// Ensures every `PatientCase` has a `Patient` after upgrading from v0.1.
    /// Pre-v0.2 cases load with `patient == nil`; we rebind them to a single
    /// "Unassigned" patient so the UI can present them without a special case.
    private func bootstrap() {
        let orphanFetch = FetchDescriptor<PatientCase>(
            predicate: #Predicate { $0.patient == nil }
        )
        let orphans = (try? context.fetch(orphanFetch)) ?? []
        guard !orphans.isEmpty else { return }

        let unassigned = unassignedPatient()
        persist("bootstrap rebind") {
            for c in orphans { c.patient = unassigned }
        }
    }

    /// Fetches the "Unassigned" patient bucket, creating it on demand.
    func unassignedPatient() -> Patient {
        if let existing = existingUnassignedPatient() {
            return existing
        }
        let p = Patient(code: Patient.unassignedCode)
        persist("create unassigned bucket") {
            context.insert(p)
        }
        return p
    }

    /// The "Unassigned" bucket if it already exists — does NOT create it.
    func existingUnassignedPatient() -> Patient? {
        let code = Patient.unassignedCode
        let fetch = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.code == code }
        )
        return (try? context.fetch(fetch))?.first
    }

    // MARK: - Patient CRUD

    func createPatient(code: String) -> Patient {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = Patient(code: trimmed.isEmpty ? "Untitled" : trimmed)
        persist("create patient") {
            context.insert(p)
        }
        return p
    }

    /// True when another patient already uses `code` (case-insensitive).
    /// Pass `excluding` when validating a rename so the patient doesn't collide with itself.
    func isCodeInUse(_ code: String, excluding: Patient? = nil) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let all = (try? context.fetch(FetchDescriptor<Patient>())) ?? []
        return all.contains { p in
            p.id != excluding?.id &&
            p.code.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    /// Non-archived patients, newest first. Used by the save-sheet and re-bind pickers.
    func activePatients() -> [Patient] {
        let fetch = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(fetch)) ?? []
    }

    func archive(_ patient: Patient) {
        persist("archive patient") {
            patient.archivedAt = Date()
        }
    }

    func unarchive(_ patient: Patient) {
        persist("unarchive patient") {
            patient.archivedAt = nil
        }
    }

    func deletePatient(_ patient: Patient) {
        // Cascade deletes the cases via the relationship rule.
        persist("delete patient") {
            context.delete(patient)
        }
    }

    // MARK: - Case CRUD

    /// Saves a new case. Returns `.failure` when the underlying context save fails so the
    /// caller can keep its UI (e.g. the save sheet) open and surface the error.
    @discardableResult
    func save(_ patientCase: PatientCase) -> Result<Void, Error> {
        if patientCase.patient == nil {
            patientCase.patient = unassignedPatient()
        }
        let result = persist("save case") {
            context.insert(patientCase)
        }
        if case .success = result {
            Task { try? await cloudSync.upload(patientCase) }
        }
        return result
    }

    /// Moves a case (visit) to a different patient — the "re-bind" path for cases
    /// that landed in the Unassigned bucket or were saved to the wrong patient.
    @discardableResult
    func reassign(_ patientCase: PatientCase, to patient: Patient) -> Result<Void, Error> {
        persist("reassign case") {
            patientCase.patient = patient
        }
    }

    @discardableResult
    func delete(_ patientCase: PatientCase) -> Result<Void, Error> {
        let id = patientCase.id
        let result = persist("delete case") {
            context.delete(patientCase)
        }
        if case .success = result {
            Task { try? await cloudSync.delete(caseId: id) }
        }
        return result
    }

    /// Suggested label for the next visit of `patient` ("Visit N", N = case count + 1).
    /// With no patient, counts the Unassigned bucket (without creating it).
    func suggestedVisitLabel(for patient: Patient?) -> String {
        let owner = patient ?? existingUnassignedPatient()
        return "Visit \((owner?.cases.count ?? 0) + 1)"
    }
}
