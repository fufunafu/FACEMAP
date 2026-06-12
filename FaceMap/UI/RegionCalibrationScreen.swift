import SwiftUI

/// Walks the practitioner through painting each `FacialRegion` by tapping vertices on
/// the captured mesh. Each tap toggles the vertex (add if missing, remove if present),
/// so users can refine without restarting. Saves to `RegionCalibrationStore`, which
/// `FaceLandmarkIndices.regionVertices` transparently merges over the placeholder defaults.
///
/// Companion to `CalibrationScreen` (named-landmark calibration). Reachable from the
/// landmark calibration screen via "Paint regions" once landmarks are done.
struct RegionCalibrationScreen: View {
    @Environment(\.dismiss) private var dismiss
    let face: CapturedFace
    /// Optional callback fired after Save & finish so the caller can refresh metric results.
    var onCommitted: (() -> Void)? = nil

    @StateObject private var meshController = FaceMeshController()
    @State private var stepIndex: Int = 0
    @State private var picked: [FacialRegion: [Int]] = [:]
    @State private var showResetConfirmation = false
    /// Set when the user confirms "Reset all" — the persistent store is only
    /// cleared on Save, so backing out without saving keeps the old calibration.
    @State private var pendingStoreClear = false

    private let order: [FacialRegion] = [
        .forehead,
        .templeR, .templeL,
        .browR, .browL,
        .tearTroughR, .tearTroughL,
        .midfaceR, .midfaceL,
        .nasolabialR, .nasolabialL,
        .lipUpper, .lipLower, .perioral,
        .marionetteR, .marionetteL,
        .chin,
        .prejowlR, .prejowlL,
        .jawlineR, .jawlineL,
    ]

    /// Suggested vertex-count window per region. Just a UX hint — Save accepts any count ≥ 1.
    private let suggestedRange: ClosedRange<Int> = 3...7

    private var current: FacialRegion? {
        stepIndex < order.count ? order[stepIndex] : nil
    }

    private var allPickedIndices: [Int] {
        Array(picked.values.joined())
    }

    private var currentRegionPicks: [Int] {
        guard let r = current else { return [] }
        return picked[r] ?? []
    }

    private var calibratedCount: Int {
        picked.values.filter { !$0.isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            ZStack(alignment: .bottom) {
                CalibrationMeshView(
                    face: face,
                    pickedIndices: allPickedIndices,
                    highlightedIndex: currentRegionPicks.last,
                    indexLabelCenter: nil,
                    controller: meshController,
                    onVertexTapped: handleTap
                )
                .frame(maxHeight: .infinity)

                viewerControls.padding(8)
            }

            instructionCard
        }
        .navigationTitle("Paint regions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveAndDismiss() }
                    .disabled(calibratedCount == 0 && !pendingStoreClear)
            }
        }
        .background(Theme.canvas)
        .confirmationDialog(
            "Reset all painted regions?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset all", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clears every painted region in this session. The saved calibration on this device is only removed when you tap Save.")
        }
        .onAppear {
            picked = RegionCalibrationStore.shared.calibrated()
            // Resume at the first uncalibrated region.
            if let resume = order.firstIndex(where: { (picked[$0] ?? []).isEmpty }) {
                stepIndex = resume
            } else {
                stepIndex = order.count
            }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(calibratedCount) of \(order.count) regions painted")
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
                Spacer()
                Button("Reset all") { showResetConfirmation = true }
                    .font(Type.caption)
                    .foregroundStyle(Theme.negative)
                    .disabled(picked.isEmpty)
            }
            ProgressView(value: Double(calibratedCount), total: Double(order.count))
                .tint(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.canvas)
    }

    // MARK: - Viewer controls (preset + reset)

    // Mesh-viewport overlay: white-on-black is deliberate (spotlight viewer),
    // but sizes come from the Type scale.
    private var viewerControls: some View {
        HStack(spacing: 6) {
            ForEach(FaceViewPreset.allCases) { preset in
                Button {
                    meshController.setPreset(preset)
                } label: {
                    Text(preset.label)
                        .font(Type.captionStrong)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.white)
            }
            Spacer(minLength: 4)
            Button {
                meshController.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(Type.captionStrong)
                    .padding(8)
            }
            .background(.ultraThinMaterial, in: Circle())
            .foregroundStyle(.white)
            .accessibilityLabel("Reset view")
        }
    }

    // MARK: - Bottom card

    private var instructionCard: some View {
        VStack(spacing: 8) {
            if let region = current {
                Text("Paint \(region.displayName)")
                    .font(Type.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(regionHint(region))
                    .font(Type.callout)
                    .foregroundStyle(Theme.inkDim)
                    .multilineTextAlignment(.center)
                Text(countLine(for: region))
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(currentRegionPicks.count >= suggestedRange.lowerBound
                                     ? Theme.positive : Theme.inkDim)
                HStack(spacing: 8) {
                    Button("Undo") { undoLastPick() }
                        .buttonStyle(.ghost)
                        .disabled(currentRegionPicks.isEmpty)
                    Button("Clear") { clearCurrentRegion() }
                        .buttonStyle(.ghost)
                        .disabled(currentRegionPicks.isEmpty)
                        .accessibilityLabel("Clear region")
                    Button("Skip") { advance() }
                        .buttonStyle(.ghost)
                    Button("Next") { advance() }
                        .buttonStyle(.primary)
                        .disabled(currentRegionPicks.isEmpty)
                }
            } else {
                Text("All regions painted.")
                    .font(Type.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("Tap Save to apply, or use Reset all to start over.")
                    .font(Type.callout)
                    .foregroundStyle(Theme.inkDim)
                    .multilineTextAlignment(.center)
                Button("Save & finish") { saveAndDismiss() }
                    .buttonStyle(.primary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceRaised)
    }

    private func countLine(for region: FacialRegion) -> String {
        let n = currentRegionPicks.count
        if n == 0 { return "Tap \(suggestedRange.lowerBound)–\(suggestedRange.upperBound) vertices around the region." }
        return "\(n) vertex\(n == 1 ? "" : "es") · suggested \(suggestedRange.lowerBound)–\(suggestedRange.upperBound)"
    }

    // MARK: - Hint text

    private func regionHint(_ region: FacialRegion) -> String {
        switch region {
        case .forehead:     return "Tap several points across the upper forehead."
        case .templeL:      return "Tap points along the patient's left temple (between brow and hairline)."
        case .templeR:      return "Tap points along the patient's right temple."
        case .browL:        return "Tap points along the left brow ridge."
        case .browR:        return "Tap points along the right brow ridge."
        case .tearTroughL:  return "Tap points along the left tear trough — the hollow under the eye."
        case .tearTroughR:  return "Tap points along the right tear trough."
        case .midfaceL:     return "Tap points across the left cheek apex."
        case .midfaceR:     return "Tap points across the right cheek apex."
        case .nasolabialL:  return "Tap points along the left nasolabial fold."
        case .nasolabialR:  return "Tap points along the right nasolabial fold."
        case .lipUpper:     return "Tap points across the upper lip vermillion."
        case .lipLower:     return "Tap points across the lower lip vermillion."
        case .perioral:     return "Tap points around the mouth (corners + above/below)."
        case .marionetteL:  return "Tap points along the left marionette line."
        case .marionetteR:  return "Tap points along the right marionette line."
        case .chin:         return "Tap points across the chin pad."
        case .prejowlL:     return "Tap points along the left pre-jowl sulcus."
        case .prejowlR:     return "Tap points along the right pre-jowl sulcus."
        case .jawlineL:     return "Tap points along the left jawline."
        case .jawlineR:     return "Tap points along the right jawline."
        }
    }

    // MARK: - Actions

    /// Tap toggles the vertex on/off for the current region.
    private func handleTap(_ vertexIdx: Int) {
        guard let region = current else { return }
        var indices = picked[region] ?? []
        if let i = indices.firstIndex(of: vertexIdx) {
            indices.remove(at: i)
        } else {
            indices.append(vertexIdx)
        }
        picked[region] = indices
    }

    private func advance() {
        if stepIndex < order.count { stepIndex += 1 }
        // Don't auto-skip already-painted regions on Next/Skip — user may want to revise.
    }

    private func undoLastPick() {
        guard let region = current,
              var indices = picked[region],
              !indices.isEmpty else { return }
        indices.removeLast()
        picked[region] = indices
    }

    private func clearCurrentRegion() {
        guard let region = current else { return }
        picked[region] = []
    }

    /// Clears the in-session picks only. The persistent store is cleared on Save
    /// (`pendingStoreClear`) so backing out without saving changes nothing.
    private func resetAll() {
        picked.removeAll()
        stepIndex = 0
        pendingStoreClear = true
    }

    private func saveAndDismiss() {
        if pendingStoreClear {
            RegionCalibrationStore.shared.clear()
        }
        // Send empty arrays through merge so they clear that region back to default.
        RegionCalibrationStore.shared.merge(picked)
        onCommitted?()
        dismiss()
    }
}
