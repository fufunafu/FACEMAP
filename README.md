# FaceMap

iOS app for licensed practitioners. Captures a 3D face mesh on iPhone (TrueDepth / ARKit), analyzes geometric proportions, and highlights facial regions that may warrant attention during filler-treatment planning.

> **Disclaimer.** FaceMap is a planning aid for use by licensed medical practitioners. It is not a medical device, does not diagnose any condition, and does not prescribe any treatment, dose, or injection site. The practitioner is the sole clinical decision-maker.

## Status

v0.1 — initial scaffold. End-to-end capture → analysis → save loop with four geometric-ratio metrics.

## Requirements

- macOS with **Xcode 15+** (Mac App Store; Command Line Tools alone are not enough)
- iOS 17.0+ deployment target
- An **iPhone X or newer** for face tracking (the simulator does not have TrueDepth)
- An Apple Developer account to sign builds for a real device
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build

```bash
# Generate the Xcode project from Project.yml
xcodegen generate

# Open in Xcode
open FaceMap.xcodeproj

# Or run tests from the command line (simulator)
xcodebuild test -scheme FaceMap -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

See `/Users/fuannegao/.claude/plans/i-want-to-create-snappy-treasure.md` for the full plan.

- `Capture/` — ARKit face tracking; produces `CapturedFace` (mesh + transform + blendshapes)
- `Analysis/` — `FaceMetric` protocol, `AnalyzableFace` with named landmark accessors, `MetricRegistry`, four metrics (thirds, fifths, golden ratio, canthal tilt)
- `Visualization/` — RealityKit mesh overlay + per-region heatmap
- `Cases/` — SwiftData persistence
- `Cloud/` — sync stubs (Phase 2)
- `UI/` — SwiftUI screens

## Calibrating landmark indices

ARKit's face mesh has stable topology (~1,220 vertices, fixed indices across all devices), so anatomical landmarks correspond to constant vertex indices. The constants in `FaceMap/Analysis/Landmarks/FaceLandmarkIndices.swift` are seeded with published reference values that **must be verified on a real device** before clinical use. See the file header for the calibration procedure.

## Roadmap

- **v0.1** (this build): geometric ratios → flagged regions
- **v0.2**: midsagittal asymmetry detection
- **v0.3**: volumetric / contour comparison against template or contralateral side
- **Phase 2**: optional cloud sync (Vercel + Neon Postgres + Vercel Blob, Sign in with Apple)

## ⚠️ Pre-production checklist

These shortcuts are acceptable while we have no real users and no clinical data on device. **Each must be addressed before the first build that ships to a practitioner.**

### 1. SwiftData migrations — when adding mandatory attributes

`FaceMap/Cases/SchemaMigrationPlan.swift` declares `SchemaV1`, `FaceMapSchema.current`, and `FaceMapMigrationPlan`. There's currently exactly one schema version. Lightweight migration handles new optional attributes automatically. Migration **only fails** for new mandatory attributes that have no value on existing rows — that's the landmine.

**Before adding a non-optional `@Attribute` or relationship to `PatientCase` or `Patient`:**
- Add a `SchemaV2: VersionedSchema` (the file's bottom-of-page comment shows the worked pattern).
- Add a `MigrationStage.custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self, willMigrate: { context in ... })` that supplies a default value for the new attribute on every existing row before the schema flip.
- Append the stage to `FaceMapMigrationPlan.stages`.
- Bump `FaceMapSchema.current` to V2.

**Default rule:** new fields ship as optional unless there's a strong reason. Optional fields don't need migration stages. The only fields that *must* be non-optional are ones the rest of the code can't safely default (e.g. an enum case with no sensible "unknown" value).

**Why no dev-mode store reset any more:** earlier versions caught migration failures and wiped the on-device store. That convenience would silently destroy patient cases in production. `FaceMapApp.init()` now lets migration failures crash so they're caught in TestFlight before they reach a practitioner.

### 2. Calibrate landmark indices before clinical use

`FaceMap/Analysis/Landmarks/FaceLandmarkIndices.swift` ships placeholder vertex indices. Until a practitioner runs the in-app calibration screen against their own captured mesh, metric outputs are not clinically meaningful. The disclaimer copy reflects this — **do not remove the disclaimer language until calibration is mandatory at first launch.**

### 3. Storage hygiene

- Confirm the `default.store` file is excluded from iCloud / iTunes backups if patient data is ever stored unencrypted.
- Audit `print(...)` statements before production — none should leak patient identifiers (`PatientCase.label`, `Patient.code`, free-text `notes`) to the device log.
