import SwiftUI
import SwiftData

@main
struct FaceMapApp: App {
    let container: ModelContainer
    let store: CaseStore

    init() {
        let c: ModelContainer
        do {
            c = try ModelContainer(for: PatientCase.self, Patient.self)
        } catch {
            // DEV-MODE FALLBACK: SwiftData lightweight migration cannot fill in mandatory
            // attributes added between schema versions (e.g. PatientCase.notes). Until we
            // ship a versioned SchemaMigrationPlan, recover by deleting the on-device store
            // and starting fresh. Pre-existing cases are lost.
            //
            // REMOVE THIS BEFORE THE FIRST PRODUCTION BUILD that has clinical data on it.
            print("⚠️ ModelContainer load failed: \(error). Resetting on-device store.")
            Self.resetOnDiskStore()
            do {
                c = try ModelContainer(for: PatientCase.self, Patient.self)
            } catch {
                fatalError("Failed to create SwiftData ModelContainer even after reset: \(error)")
            }
        }
        self.container = c
        self.store = CaseStore(context: c.mainContext)
    }

    private static func resetOnDiskStore() {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                     in: .userDomainMask).first else { return }
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: support.appendingPathComponent(name))
        }
    }

    var body: some Scene {
        WindowGroup {
            DisclaimerGate {
                ContentView().environmentObject(store)
            }
        }
        .modelContainer(container)
    }
}
