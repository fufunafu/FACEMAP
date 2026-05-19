import SwiftUI
import SwiftData

@main
struct FaceMapApp: App {
    let container: ModelContainer
    let store: CaseStore

    init() {
        // iOS-17-compatible billboarding for metric-construction labels (replaces the
        // iOS-18-only `BillboardComponent`). Must register before any scene is built.
        BillboardSystem.register()

        do {
            container = try ModelContainer(
                for: FaceMapSchema.current,
                migrationPlan: FaceMapMigrationPlan.self,
                configurations: ModelConfiguration(schema: FaceMapSchema.current)
            )
        } catch {
            // We intentionally do NOT reset the on-disk store here. If migration fails on
            // device, that's a bug to investigate — silent data loss is worse than a crash.
            // See README "⚠️ Pre-production checklist" for the migration-pattern reference.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
        self.store = CaseStore(context: container.mainContext)
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
