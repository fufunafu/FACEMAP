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

    private let order: [AnatomicalLandmark] = AnatomicalLandmark.calibrationOrder

    private var current: AnatomicalLandmark? {
        stepIndex < order.count ? order[stepIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            ZStack(alignment: .bottom) {
                CalibrationMeshView(
                    face: face,
                    pickedIndices: Array(picked.values),
                    highlightedIndex: lastTappedIndex,
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
                    .disabled(picked.isEmpty)
            }
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
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset all") { resetAll() }
                    .font(.caption)
                    .disabled(picked.isEmpty)
            }
            ProgressView(value: Double(picked.count), total: Double(order.count))
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
            if let lm = current {
                Text("Tap \(lm.displayLabel)")
                    .font(.headline)
                Text(lm.calibrationHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let idx = picked[lm] {
                    Text("Picked vertex \(idx)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                }
                HStack {
                    Button("Undo") { undo() }
                        .buttonStyle(.bordered)
                        .disabled(stepIndex == 0 && picked[lm] == nil)
                    Button("Skip") { skip() }
                        .buttonStyle(.bordered)
                    Button(picked[lm] == nil ? "" : "Next") { advance() }
                        .buttonStyle(.borderedProminent)
                        .disabled(picked[lm] == nil)
                        .opacity(picked[lm] == nil ? 0 : 1)
                }
            } else {
                Text("All landmarks calibrated.")
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

    private func resetAll() {
        picked.removeAll()
        stepIndex = 0
        lastTappedIndex = nil
        LandmarkCalibrationStore.shared.clear()
    }

    private func saveAndDismiss() {
        LandmarkCalibrationStore.shared.merge(picked)
        onCommitted?()
        dismiss()
    }
}
