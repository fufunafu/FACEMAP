import SwiftUI
import SwiftData
import LocalAuthentication
import os

@main
struct FaceMapApp: App {
    let container: ModelContainer
    let store: CaseStore

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // iOS-17-compatible billboarding for metric-construction labels (replaces the
        // iOS-18-only `BillboardComponent`). Must register before any scene is built.
        BillboardSystem.register()

        // Patient face photos and meshes are `.externalStorage` blobs that Core Data
        // writes to a `_SUPPORT/_EXTERNAL_DATA` directory NEXT TO the store file —
        // excluding only the store + sidecars would still let photos travel into
        // iCloud/Finder backups. We therefore pin the store inside a dedicated
        // directory and exclude that whole directory from backup.
        let storeURL = SecureStoreLocation.prepareStoreURL()

        do {
            container = try ModelContainer(
                for: FaceMapSchema.current,
                migrationPlan: FaceMapMigrationPlan.self,
                configurations: ModelConfiguration(schema: FaceMapSchema.current, url: storeURL)
            )
        } catch {
            // We intentionally do NOT reset the on-disk store here. If migration fails on
            // device, that's a bug to investigate — silent data loss is worse than a crash.
            // See README "⚠️ Pre-production checklist" for the migration-pattern reference.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
        self.store = CaseStore(context: container.mainContext)

        // The container has now materialised the store (and any external-data dirs);
        // sweep the directory so every file carries the exclusion flag.
        SecureStoreLocation.excludeStoreTreeFromBackup()
        #if DEBUG
        SecureStoreLocation.assertStoreTreeExcluded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            BiometricGate {
                DisclaimerGate {
                    ContentView().environmentObject(store)
                }
            }
            // App-switcher snapshot redaction: whenever the scene is not active
            // (backgrounded, app switcher, system interruptions) cover the entire
            // window with an opaque brand splash so no patient photo is ever
            // written into the iOS snapshot. Composes with `BiometricGate`, which
            // re-locks underneath on background when the lock is enabled.
            .overlay {
                if scenePhase != .active {
                    PrivacyShield()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    // Saves may have created new external-data files since launch;
                    // re-sweep before the system gets a chance to back anything up.
                    SecureStoreLocation.excludeStoreTreeFromBackup()
                    #if DEBUG
                    SecureStoreLocation.assertStoreTreeExcluded()
                    #endif
                }
            }
        }
        .modelContainer(container)
    }
}

// MARK: - Secure store location & backup exclusion

/// Owns where the SwiftData store lives on disk and guarantees the entire store
/// tree — SQLite file, `-shm`/`-wal` sidecars, and the `_SUPPORT/_EXTERNAL_DATA`
/// directories holding patient photos and meshes — is excluded from iCloud and
/// Finder backups.
enum SecureStoreLocation {

    private static let log = Logger(subsystem: "com.fuanne.facemap", category: "backup-exclusion")

    /// Dedicated directory so `isExcludedFromBackup` can be applied to the whole
    /// subtree, covering external-storage blobs Core Data creates later.
    static var storeDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "CaseStore", directoryHint: .isDirectory)
    }

    /// The store keeps SwiftData's historical file name (`default.store`) so that
    /// migrating an existing store is a plain file move — Core Data derives the
    /// external-data directory name (`.default_SUPPORT`) from the file name, so
    /// renaming nothing means old blobs remain addressable.
    static var storeURL: URL {
        storeDirectory.appending(path: "default.store")
    }

    /// Creates the dedicated store directory, migrates any pre-existing store from
    /// the legacy Application Support root into it, and excludes the directory from
    /// backup. Returns the URL to hand to `ModelConfiguration(url:)`.
    static func prepareStoreURL() -> URL {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        } catch {
            log.error("Failed to create store directory \(storeDirectory.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }

        migrateLegacyStoreIfNeeded()
        excludeStoreTreeFromBackup()
        return storeURL
    }

    /// First-run migration: earlier builds let SwiftData place `default.store`
    /// directly in Application Support. Move the store file, its `-shm`/`-wal`
    /// sidecars, and the hidden `.default_SUPPORT` external-data directory into
    /// the dedicated directory so existing cases survive the relocation.
    private static func migrateLegacyStoreIfNeeded() {
        let fm = FileManager.default
        let legacyRoot = URL.applicationSupportDirectory
        let legacyStore = legacyRoot.appending(path: "default.store")

        guard fm.fileExists(atPath: legacyStore.path) else { return }
        guard !fm.fileExists(atPath: storeURL.path) else {
            log.error("Both legacy and relocated stores exist; leaving legacy store untouched at \(legacyStore.path, privacy: .public)")
            return
        }

        let contents = (try? fm.contentsOfDirectory(
            at: legacyRoot,
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []

        for item in contents {
            let name = item.lastPathComponent
            // default.store, default.store-shm, default.store-wal, and the hidden
            // .default_SUPPORT/_EXTERNAL_DATA directory (plus any other sidecar
            // Core Data derives from the store name).
            guard name.hasPrefix("default.store") || name.hasPrefix(".default") else { continue }
            let destination = storeDirectory.appending(path: name)
            do {
                try fm.moveItem(at: item, to: destination)
                log.info("Migrated legacy store item \(name, privacy: .public) into \(storeDirectory.path, privacy: .public)")
            } catch {
                log.error("Failed to migrate legacy store item \(name, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Sets `isExcludedFromBackup` on the store directory and on every file and
    /// subdirectory beneath it (belt and braces: the directory flag alone excludes
    /// the subtree, but flagging each item keeps the guarantee auditable).
    static func excludeStoreTreeFromBackup() {
        excludeFromBackup(storeDirectory)
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: storeDirectory,
            includingPropertiesForKeys: [.isExcludedFromBackupKey]
        ) else { return }
        for case let item as URL in enumerator {
            excludeFromBackup(item)
        }
    }

    private static func excludeFromBackup(_ url: URL) {
        var target = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try target.setResourceValues(values)
            log.info("Excluded from backup: \(target.path, privacy: .public)")
        } catch {
            log.error("Failed to exclude \(target.path, privacy: .public) from backup: \(error.localizedDescription, privacy: .public)")
        }
    }

    #if DEBUG
    /// Debug-only audit: walks the entire store tree and asserts every item carries
    /// the backup-exclusion flag. Run after container creation and on backgrounding
    /// (i.e. after any saves of new external-storage blobs).
    static func assertStoreTreeExcluded() {
        let fm = FileManager.default
        var urls: [URL] = [storeDirectory]
        if let enumerator = fm.enumerator(
            at: storeDirectory,
            includingPropertiesForKeys: [.isExcludedFromBackupKey]
        ) {
            for case let item as URL in enumerator { urls.append(item) }
        }
        for url in urls {
            let excluded = (try? url.resourceValues(forKeys: [.isExcludedFromBackupKey]))?
                .isExcludedFromBackup ?? false
            assert(excluded, "Store item NOT excluded from backup: \(url.path)")
            if !excluded {
                log.fault("AUDIT FAILURE — store item not excluded from backup: \(url.path, privacy: .public)")
            }
        }
        log.debug("Backup-exclusion audit passed for \(urls.count) item(s) under \(storeDirectory.path, privacy: .public)")
    }
    #endif
}

// MARK: - Biometric gate

/// Enforces the Settings "Lock with Face ID" preference at the root of the window.
/// When `biometricLockEnabled` is on, device-owner authentication (Face ID with
/// device-passcode fallback) is required on launch and every time the scene returns
/// to the foreground after backgrounding. Until authenticated, an opaque
/// brand-styled lock screen covers all patient data. When the preference is off,
/// behavior is unchanged.
private struct BiometricGate<Content: View>: View {
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @State private var authMessage: String?
    /// Set when device-owner authentication cannot run at all (no passcode set).
    /// We explain rather than brick the app — the lock is unenforceable then.
    @State private var lockUnavailable = false

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
            if biometricLockEnabled && !isUnlocked {
                lockScreen
            }
        }
        .onAppear {
            if biometricLockEnabled && !isUnlocked { authenticate() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                // Re-lock on background only — the Face ID system sheet itself
                // drives the scene through `.inactive`, so locking there would loop.
                if biometricLockEnabled { isUnlocked = false }
            case .active:
                if biometricLockEnabled && !isUnlocked && !isAuthenticating { authenticate() }
            default:
                break
            }
        }
    }

    private var lockScreen: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                BrandMark(.large)
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.inkDim)
                Text("Locked")
                    .font(Type.titleLarge)
                    .foregroundStyle(Theme.ink)
                if let authMessage {
                    Text(authMessage)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
                Button {
                    if lockUnavailable {
                        // No passcode on the device: the lock cannot be enforced.
                        // Let the practitioner in rather than bricking the app.
                        isUnlocked = true
                    } else {
                        authenticate()
                    }
                } label: {
                    Text(lockUnavailable ? "Continue without lock" : "Unlock")
                }
                .buttonStyle(.primary)
                .disabled(isAuthenticating)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.light)
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        let ctx = LAContext()
        var error: NSError?
        // .deviceOwnerAuthentication = biometrics with device-passcode fallback.
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let laError = error as? LAError, laError.code == .passcodeNotSet {
                authMessage = "This device has no passcode, so the app lock can't be enforced. Set a passcode in iOS Settings to use the lock."
            } else {
                authMessage = "Authentication isn't available on this device right now."
            }
            lockUnavailable = true
            return
        }
        lockUnavailable = false
        isAuthenticating = true
        ctx.evaluatePolicy(.deviceOwnerAuthentication,
                           localizedReason: "Unlock FaceMap to view saved cases.") { ok, evalError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if ok {
                    isUnlocked = true
                    authMessage = nil
                } else if let laError = evalError as? LAError, laError.code == .userCancel {
                    authMessage = "Authentication was cancelled."
                } else {
                    authMessage = "Authentication failed. Try again."
                }
            }
        }
    }
}

// MARK: - Privacy shield

/// Opaque brand splash shown whenever the scene is not active so the iOS
/// app-switcher snapshot never contains patient photos or analysis data.
private struct PrivacyShield: View {
    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            BrandMark(.large)
        }
        .preferredColorScheme(.light)
    }
}
