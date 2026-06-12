import SwiftUI

/// Walks the practitioner through tapping each anatomical landmark on a captured mesh.
/// Saves the resulting vertex indices to `LandmarkCalibrationStore`, which transparently
/// overrides the placeholder values in `FaceLandmarkIndices`.
struct CalibrationScreen: View {
    @Environment(\.dismiss) private var dismiss
    let face: CapturedFace
    /// Optional callback fired after Save & finish so the caller can refresh metric results.
    var onCommitted: (() -> Void)? = nil

    @StateObject private var meshController = FaceMeshController()
    @State private var stepIndex: Int = 0
    @State private var picked: [AnatomicalLandmark: Int] = [:]
    @State private var lastTappedIndex: Int? = nil
    @State private var showIndexLabels = false
    @State private var showResetConfirmation = false
    /// Set when the user confirms "Reset all" — the persistent store is only
    /// cleared on Save, so backing out without saving keeps the old calibration.
    @State private var pendingStoreClear = false

    private let order: [AnatomicalLandmark] = AnatomicalLandmark.calibrationOrder

    private var current: AnatomicalLandmark? {
        stepIndex < order.count ? order[stepIndex] : nil
    }

    /// Where to show vertex-index labels: around the last tap, falling back to the
    /// current landmark's effective (picked or seeded) vertex.
    private var indexLabelCenter: Int? {
        lastTappedIndex ?? current.flatMap { picked[$0] ?? FaceLandmarkIndices.vertexIndex[$0] }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            ZStack(alignment: .bottom) {
                CalibrationMeshView(
                    face: face,
                    pickedIndices: Array(picked.values),
                    highlightedIndex: lastTappedIndex,
                    indexLabelCenter: showIndexLabels ? indexLabelCenter : nil,
                    controller: meshController,
                    onVertexTapped: handleTap
                )
                .frame(maxHeight: .infinity)

                viewerControls.padding(8)
            }

            instructionCard
        }
        .navigationTitle("Calibrate landmarks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RegionCalibrationScreen(face: face, onCommitted: onCommitted)
                } label: {
                    Image(systemName: "paintbrush")
                        .accessibilityLabel("Paint regions")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveAndDismiss() }
                    .disabled(picked.isEmpty && !pendingStoreClear)
            }
        }
        .background(Theme.canvas)
        .confirmationDialog(
            "Reset all calibrated landmarks?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset all", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clears every picked landmark in this session. The saved calibration on this device is only removed when you tap Save.")
        }
        .onAppear {
            picked = LandmarkCalibrationStore.shared.calibrated()
            // Resume at the first uncalibrated landmark.
            if let resume = order.firstIndex(where: { picked[$0] == nil }) {
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
                Text("\(picked.count) of \(order.count) calibrated")
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
                Spacer()
                Button("Reset all") { showResetConfirmation = true }
                    .font(Type.caption)
                    .foregroundStyle(Theme.negative)
                    .disabled(picked.isEmpty)
            }
            ProgressView(value: Double(picked.count), total: Double(order.count))
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
                showIndexLabels.toggle()
            } label: {
                Image(systemName: "textformat.123")
                    .font(Type.captionStrong)
                    .padding(8)
            }
            .background(showIndexLabels ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial),
                        in: Circle())
            .foregroundStyle(showIndexLabels ? Theme.ink : .white)
            .accessibilityLabel(showIndexLabels ? "Hide vertex indices" : "Show vertex indices")
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
            if let lm = current {
                Text("Tap \(lm.displayLabel)")
                    .font(Type.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(lm.calibrationHint)
                    .font(Type.callout)
                    .foregroundStyle(Theme.inkDim)
                    .multilineTextAlignment(.center)
                if let idx = picked[lm] {
                    Text("Picked vertex \(idx)")
                        .font(Type.caption.monospacedDigit())
                        .foregroundStyle(Theme.positive)
                }
                HStack(spacing: 8) {
                    Button("Undo") { undo() }
                        .buttonStyle(.ghost)
                        .disabled(stepIndex == 0 && picked[lm] == nil)
                    Button("Skip") { skip() }
                        .buttonStyle(.ghost)
                    Button(picked[lm] == nil ? "" : "Next") { advance() }
                        .buttonStyle(.primary)
                        .disabled(picked[lm] == nil)
                        .opacity(picked[lm] == nil ? 0 : 1)
                }
            } else {
                Text("All landmarks calibrated.")
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

    // MARK: - Actions

    private func handleTap(_ vertexIdx: Int) {
        guard let lm = current else { return }
        picked[lm] = vertexIdx
        lastTappedIndex = vertexIdx
    }

    private func advance() {
        if stepIndex < order.count { stepIndex += 1 }
        // Skip past landmarks already calibrated (so user doesn't redo them).
        while stepIndex < order.count, picked[order[stepIndex]] != nil {
            stepIndex += 1
        }
        lastTappedIndex = nil
    }

    private func skip() {
        if stepIndex < order.count - 1 {
            stepIndex += 1
        } else {
            stepIndex = order.count
        }
        lastTappedIndex = nil
    }

    private func undo() {
        if let lm = current, picked[lm] != nil {
            picked[lm] = nil
            lastTappedIndex = nil
            return
        }
        if stepIndex > 0 {
            stepIndex -= 1
            if let lm = current { picked[lm] = nil }
            lastTappedIndex = nil
        }
    }

    /// Clears the in-session picks only. The persistent store is cleared on Save
    /// (`pendingStoreClear`) so backing out without saving changes nothing.
    private func resetAll() {
        picked.removeAll()
        stepIndex = 0
        lastTappedIndex = nil
        pendingStoreClear = true
    }

    private func saveAndDismiss() {
        if pendingStoreClear {
            LandmarkCalibrationStore.shared.clear()
        }
        LandmarkCalibrationStore.shared.merge(picked)
        onCommitted?()
        dismiss()
    }
}
