import SwiftUI
import SwiftData

struct AnalysisScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: CaseStore

    let face: CapturedFace
    /// When opened from a stored case, edits go back to that case.
    var existingCase: PatientCase? = nil

    @State private var results: [MetricResult] = []
    @State private var saveLabel = ""
    @State private var showingSaveSheet = false
    @State private var selectedRegion: FacialRegion?
    @State private var pane: Pane = .metrics

    private enum Pane: String, CaseIterable, Identifiable {
        case metrics, regions
        var id: String { rawValue }
        var label: String { self == .metrics ? "Metrics" : "Regions" }
    }

    private var regionSeverity: [FacialRegion: MetricResult.Severity] {
        results.flaggedRegionsBySeverity
    }

    var body: some View {
        VStack(spacing: 0) {
            FaceMeshOverlay(face: face, regionSeverity: regionSeverity)
                .frame(height: 320)
                .background(Color.black)

            Picker("View", selection: $pane) {
                ForEach(Pane.allCases) { p in Text(p.label).tag(p) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch pane {
            case .metrics: metricsList
            case .regions: regionsList
            }

            footer
        }
        .navigationTitle(existingCase?.label ?? "Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if existingCase == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { showingSaveSheet = true }
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) { saveSheet }
        .sheet(item: $selectedRegion) { region in
            RegionDetailView(region: region, allResults: results)
                .presentationDetents([.medium, .large])
        }
        .task {
            results = MetricRegistry.defaultRegistry()
                .evaluateAll(on: AnalyzableFace(face))
        }
    }

    private var metricsList: some View {
        List(results, id: \.metricId) { r in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(r.metricName).font(.headline)
                    Spacer()
                    Circle().fill(r.severity.color).frame(width: 10, height: 10)
                }
                Text(formatValue(r))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                if let n = r.notes {
                    Text(n).font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var regionsList: some View {
        RegionHeatmapView(
            regionSeverity: regionSeverity,
            onSelect: { selectedRegion = $0 }
        )
    }

    private var footer: some View {
        Text(DisclaimerCopy.analysisFooter)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Patient code (no PII)", text: $saveLabel)
                } footer: {
                    Text("Use a code such as \"P-014 Visit 2\". The label is stored verbatim on this device.")
                }
            }
            .navigationTitle("Save case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let label = saveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !label.isEmpty else { return }
                        let pc = PatientCase(label: label, capturedFace: face, metricResults: results)
                        store.save(pc)
                        showingSaveSheet = false
                        dismiss()
                    }
                    .disabled(saveLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func formatValue(_ r: MetricResult) -> String {
        if r.value.isNaN { return r.notes ?? "Unavailable" }
        switch r.metricId {
        case CanthalTiltMetric.id:
            return String(format: "min %.1f° (target %.0f–%.0f°)", r.value, r.target.lowerBound, r.target.upperBound)
        case FacialThirdsMetric.id, FacialFifthsMetric.id:
            return String(format: "worst deviation %.1f%% (target ≤ %.0f%%)", r.value * 100, r.target.upperBound * 100)
        case GoldenRatioMetric.id:
            return String(format: "worst |Δ from φ| %.1f%% (target ≤ %.0f%%)", r.value * 100, r.target.upperBound * 100)
        default:
            return String(format: "%.3f", r.value)
        }
    }
}

extension FacialRegion: Identifiable {
    var id: String { rawValue }
}
