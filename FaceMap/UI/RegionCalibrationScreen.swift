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
                    .disabled(calibratedCount == 0)
            }
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
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset all") { resetAll() }
                    .font(.caption)
                    .disabled(picked.isEmpty)
            }
            ProgressView(value: Double(calibratedCount), total: Double(order.count))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Viewer controls (preset + reset)

    private var viewerControls: some View {
        HStack(spacing: 6) {
            ForEach(FaceViewPreset.allCases) { preset in
                Button {
                    meshController.setPreset(preset)
                } label: {
                    Text(preset.label)
                        .font(.caption.weight(.semibold))
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
                    .font(.caption.weight(.semibold))
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
                    .font(.headline)
                Text(regionHint(region))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(countLine(for: region))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(currentRegionPicks.count >= suggestedRange.lowerBound
                                     ? .green : .secondary)
                HStack {
                    Button("Undo") { undoLastPick() }
                        .buttonStyle(.bordered)
                        .disabled(currentRegionPicks.isEmpty)
                    Button("Clear region") { clearCurrentRegion() }
                        .buttonStyle(.bordered)
                        .disabled(currentRegionPicks.isEmpty)
                    Button("Skip") { advance() }
                        .buttonStyle(.bordered)
                    Button("Next") { advance() }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentRegionPicks.isEmpty)
                }
            } else {
                Text("All regions painted.")
                    .font(.headline)
                Text("Tap Save to apply, or use Reset all to start over.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Save & finish") { saveAndDismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
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

    private func resetAll() {
        picked.removeAll()
        stepIndex = 0
        RegionCalibrationStore.shared.clear()
    }

    private func saveAndDismiss() {
        // Send empty arrays through merge so they clear that region back to default.
        RegionCalibrationStore.shared.merge(picked)
        onCommitted?()
        dismiss()
    }
}
