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
        Self.excludeStoreFromBackup(container)
    }

    /// Patient meshes and notes are stored unencrypted in the SwiftData store, so the
    /// store (and its SQLite sidecars) must not travel into iCloud / Finder backups.
    /// See README "⚠️ Pre-production checklist", item 3.
    private static func excludeStoreFromBackup(_ container: ModelContainer) {
        let fm = FileManager.default
        for configuration in container.configurations {
            for suffix in ["", "-shm", "-wal"] {
                var url = URL(fileURLWithPath: configuration.url.path + suffix)
                guard fm.fileExists(atPath: url.path) else { continue }
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                do {
                    try url.setResourceValues(values)
                } catch {
                    assertionFailure("Failed to exclude \(url.lastPathComponent) from backup: \(error)")
                }
            }
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
