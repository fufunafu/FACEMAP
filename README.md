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

### 1. Replace the SwiftData dev-mode store reset with a versioned migration

`FaceMapApp.swift` → `init()` currently catches any `ModelContainer` load failure and **deletes the on-device store** (`resetOnDiskStore()`). This is convenient during development because adding a non-optional attribute (e.g. `PatientCase.notes: String`) makes lightweight migration fail, and the reset gets the app launching again — but it would silently destroy patient cases in production.

**Action before production:**
- Remove the `catch → resetOnDiskStore()` block; let load failures crash so we notice them in TestFlight before any practitioner sees them.
- Adopt a `VersionedSchema` + `SchemaMigrationPlan` ([Apple docs](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)). One `VersionedSchema` per shipped schema; one migration stage between consecutive versions; each stage supplies defaults (or computed values) for new mandatory attributes.
- Schema-fields currently relying on the reset (audit before each release):
  - `PatientCase.notes: String` — added v0.2; migrate existing rows with `""`.
  - `PatientCase.patient: Patient?` — already optional; the `bootstrap()` migration in `CaseStore` rebinds orphans to an "Unassigned" `Patient`. Keep that logic when you switch to a versioned plan.
  - `PatientCase.annotationsJSON: Data?` — already optional; no migration default needed.
  - Any future non-optional field added to `PatientCase` or `Patient` **must** ship with a migration default.

### 2. Calibrate landmark indices before clinical use

`FaceMap/Analysis/Landmarks/FaceLandmarkIndices.swift` ships placeholder vertex indices. Until a practitioner runs the in-app calibration screen against their own captured mesh, metric outputs are not clinically meaningful. The disclaimer copy reflects this — **do not remove the disclaimer language until calibration is mandatory at first launch.**

### 3. Storage hygiene

- Confirm the `default.store` file is excluded from iCloud / iTunes backups if patient data is ever stored unencrypted.
- Audit `print(...)` statements before production — none should leak patient identifiers (`PatientCase.label`, `Patient.code`, free-text `notes`) to the device log.
