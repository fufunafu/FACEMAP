import Foundation
import SwiftData

/// Thin facade over a `ModelContext`. Exists so call sites don't depend directly on SwiftData
/// and the cloud-sync layer can be inserted without touching the UI.
final class CaseStore: ObservableObject {
    let context: ModelContext
    private let cloudSync: any CloudSync

    init(context: ModelContext, cloudSync: any CloudSync = NoopCloudSync()) {
        self.context = context
        self.cloudSync = cloudSync
        bootstrap()
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
        for c in orphans { c.patient = unassigned }
        try? context.save()
    }

    /// Fetches the "Unassigned" patient bucket, creating it on demand.
    func unassignedPatient() -> Patient {
        let code = Patient.unassignedCode
        let fetch = FetchDescriptor<Patient>(
            predicate: #Predicate { $0.code == code }
        )
        if let existing = (try? context.fetch(fetch))?.first {
            return existing
        }
        let p = Patient(code: code)
        context.insert(p)
        try? context.save()
        return p
    }

    // MARK: - Patient CRUD

    func createPatient(code: String) -> Patient {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = Patient(code: trimmed.isEmpty ? "Untitled" : trimmed)
        context.insert(p)
        try? context.save()
        return p
    }

    func archive(_ patient: Patient) {
        patient.archivedAt = Date()
        try? context.save()
    }

    func unarchive(_ patient: Patient) {
        patient.archivedAt = nil
        try? context.save()
    }

    func deletePatient(_ patient: Patient) {
        // Cascade deletes the cases via the relationship rule.
        context.delete(patient)
        try? context.save()
    }

    // MARK: - Case CRUD

    func save(_ patientCase: PatientCase) {
        if patientCase.patient == nil {
            patientCase.patient = unassignedPatient()
        }
        context.insert(patientCase)
        do {
            try context.save()
            Task { try? await cloudSync.upload(patientCase) }
        } catch {
            print("CaseStore.save failed:", error)
        }
    }

    func delete(_ patientCase: PatientCase) {
        let id = patientCase.id
        context.delete(patientCase)
        try? context.save()
        Task { try? await cloudSync.delete(caseId: id) }
    }
}
