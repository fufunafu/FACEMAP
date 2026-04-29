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
    }

    func save(_ patientCase: PatientCase) {
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
