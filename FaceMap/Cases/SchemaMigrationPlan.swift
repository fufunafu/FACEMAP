import Foundation
import os
import SwiftData

/// Versioned schema scaffold for FaceMap.
///
/// Today there is exactly **one** declared version (`SchemaV1`) — the v0.2 model set.
/// Pre-v0.2 stores either don't exist any more (the dev-mode reset wiped them) or are
/// migrated by SwiftData's lightweight migration into V1: every previously-added
/// attribute (`PatientCase.notes`, `PatientCase.annotationsJSON`, `PatientCase.patient`)
/// is now optional, so lightweight migration succeeds without a custom stage.
///
/// **When you add a new mandatory attribute or relationship**, the safe pattern is:
///
///   1. Declare a `SchemaV2` enum that imports the *current* set of `@Model` types
///      (effectively a frozen snapshot — copy them under that namespace, OR use a
///      typealias to the live type if you'd rather not duplicate the source).
///   2. Add a `static let stage = MigrationStage.custom(...)` that supplies a value
///      for the new attribute on every existing row before flipping the schema.
///   3. Append the stage to `FaceMapMigrationPlan.stages`.
///   4. Bump `FaceMapSchema.versionedSchema` references to V2.
///
/// Worked example in a comment block at the bottom of this file.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [PatientCase.self, Patient.self]
    }
}

/// Single source of truth for the schema FaceMap is currently running.
enum FaceMapSchema {
    static let current = Schema(versionedSchema: SchemaV1.self)
}

/// Migration plan — empty today (only one schema version), but exists so future
/// migrations have an obvious place to land.
enum FaceMapMigrationPlan: SchemaMigrationPlan {
    /// A failed migration fetch/save must never be invisible — corrupt or
    /// half-migrated stores are exactly what we need a forensic trail for.
    /// Migration stages MUST log through this (do/catch, never `try?`).
    static let logger = Logger(subsystem: "com.fuanne.facemap", category: "Migration")

    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/* -----------------------------------------------------------------------------

EXAMPLE — adding a mandatory `Patient.consentVersion: Int` field.
Note the do/catch + logger: a failed migration fetch/save must not be silent
(`try?` would hide a half-migrated store).

    enum SchemaV2: VersionedSchema {
        static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
        static var models: [any PersistentModel.Type] { [PatientCase.self, Patient.self] }
    }

    extension FaceMapMigrationPlan {
        static var stagesV2: [MigrationStage] {
            [
                .custom(
                    fromVersion: SchemaV1.self,
                    toVersion:   SchemaV2.self,
                    willMigrate: { context in
                        // Backfill consentVersion = 1 on every existing patient.
                        let request = FetchDescriptor<Patient>()
                        do {
                            for p in try context.fetch(request) {
                                p.consentVersion = 1
                            }
                            try context.save()
                        } catch {
                            logger.error("V1→V2 consentVersion backfill failed: \(String(describing: error), privacy: .public)")
                            throw error   // abort the migration rather than ship a half-migrated store
                        }
                    },
                    didMigrate: nil
                )
            ]
        }
    }

Then update `FaceMapMigrationPlan.schemas` and `.stages` to include V2.

----------------------------------------------------------------------------- */
