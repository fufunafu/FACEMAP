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
    @State private var pane: Pane = .wheel
    @State private var focusedDomain: FaceDomain? = nil
    @State private var notes: String = ""
    @State private var notesLoaded = false
    @State private var pins: [AnnotationPin] = []
    @State private var pinsLoaded = false
    @State private var showingAnnotations = false
    @State private var pdfShareItem: PDFShareItem?
    @StateObject private var meshController = FaceMeshController()

    private enum Pane: String, CaseIterable, Identifiable {
        case wheel, mesh, regions, notes
        var id: String { rawValue }
        var label: String {
            switch self {
            case .wheel:   return "Wheel"
            case .mesh:    return "Mesh"
            case .regions: return "Regions"
            case .notes:   return "Notes"
            }
        }
    }

    private var regionSeverity: [FacialRegion: MetricResult.Severity] {
        results.flaggedRegionsBySeverity
    }

    private var regionDomain: [FacialRegion: FaceDomain] {
        results.regionDomainsByWorstSeverity
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Picker("View", selection: $pane) {
                    ForEach(Pane.allCases) { p in Text(p.label).tag(p) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                paneContent
                    .frame(maxHeight: .infinity)

                DisclaimerBanner()
            }
        }
        .navigationTitle(existingCase?.label ?? "Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let _ = existingCase {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(Theme.ink)
                    .accessibilityLabel("Export plan")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAnnotations = true
                } label: {
                    Image(systemName: "mappin")
                        .overlay(alignment: .topTrailing) {
                            if !pins.isEmpty {
                                Text("\(pins.count)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Theme.canvas)
                                    .padding(.horizontal, 4).padding(.vertical, 1)
                                    .background(Theme.ink, in: Capsule())
                                    .offset(x: 6, y: -6)
                            }
                        }
                        .accessibilityLabel("Annotation pins")
                }
                .foregroundStyle(Theme.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CalibrationScreen(face: face) {
                        results = MetricRegistry.defaultRegistry()
                            .evaluateAll(on: AnalyzableFace(face))
                    }
                } label: {
                    Image(systemName: "scope")
                        .accessibilityLabel("Calibrate landmarks")
                }
                .foregroundStyle(Theme.ink)
            }
            if existingCase == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { showingSaveSheet = true }
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) { saveSheet }
        .sheet(isPresented: $showingAnnotations) {
            AnnotationSheet(face: face, pins: $pins) {
                if let c = existingCase {
                    c.updateAnnotations(pins)
                    try? store.context.save()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $pdfShareItem) { item in
            ShareSheet(items: [item.url])
        }
        .sheet(item: $selectedRegion) { region in
            RegionDetailView(region: region, allResults: results)
                .presentationDetents([.medium, .large])
        }
        .task {
            results = MetricRegistry.defaultRegistry()
                .evaluateAll(on: AnalyzableFace(face))
            if !notesLoaded {
                notes = existingCase?.notes ?? ""
                notesLoaded = true
            }
            if !pinsLoaded {
                pins = existingCase?.annotations ?? []
                pinsLoaded = true
            }
        }
        .onChange(of: notes) { _, newValue in
            // Persist as the user types, only when bound to a saved case.
            if let c = existingCase {
                c.notes = newValue
                try? store.context.save()
            }
        }
    }

    // MARK: - Header (mesh + wheel side by side)

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottom) {
                FaceMeshOverlay(
                    face: face,
                    regionSeverity: regionSeverity,
                    regionDomain: regionDomain,
                    controller: meshController
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)

                viewerControls
                    .padding(8)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

            AestheticWheel(
                results: results,
                diameter: 180,
                showsLabels: false,
                onTapDomain: { d in
                    focusedDomain = (focusedDomain == d) ? nil : d
                    pane = .wheel
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Pane content

    @ViewBuilder
    private var paneContent: some View {
        switch pane {
        case .wheel:   wheelPane
        case .mesh:    meshPane
        case .regions: regionsPane
        case .notes:   notesPane
        }
    }

    // MARK: Wheel pane — domain breakdown

    private var wheelPane: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let f = focusedDomain {
                    HStack(spacing: 8) {
                        Text("Filtered: \(f.displayName)")
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkDim)
                        Spacer()
                        Button("Clear") { focusedDomain = nil }
                            .font(Type.caption)
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.horizontal, 16)
                }

                ForEach(domainsToShow) { d in
                    domainSection(d)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var domainsToShow: [FaceDomain] {
        if let f = focusedDomain { return [f] }
        return FaceDomain.allCases
    }

    private func domainSection(_ d: FaceDomain) -> some View {
        let inDomain = results.filter { $0.domain == d }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(d.hue).frame(width: 8, height: 8)
                Text(d.displayName.uppercased())
                    .font(Type.sectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 16)

            if inDomain.isEmpty {
                Text("No metrics yet for this domain — coming in v0.3.")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 6) {
                    ForEach(inDomain, id: \.metricId) { r in
                        MetricRow(
                            result: r,
                            domain: r.domain,
                            valueText: formatValue(r)
                        )
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

                        if r.metricId == AsymmetryMetric.id {
                            AsymmetryDivergentChart(
                                result: r,
                                pairs: AsymmetryDivergentChart.computePairs(
                                    from: AnalyzableFace(face)
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Mesh pane — full-bleed mesh

    private var meshPane: some View {
        ZStack(alignment: .bottom) {
            FaceMeshOverlay(
                face: face,
                regionSeverity: regionSeverity,
                regionDomain: regionDomain,
                controller: meshController
            )
            .background(Theme.canvas)

            domainLegend
                .padding(.bottom, 12)
        }
    }

    private var domainLegend: some View {
        HStack(spacing: 14) {
            ForEach(FaceDomain.allCases) { d in
                HStack(spacing: 6) {
                    Circle().fill(d.hue).frame(width: 8, height: 8)
                    Text(legendLabel(for: d))
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
    }

    private func legendLabel(for d: FaceDomain) -> String {
        switch d {
        case .mechanical: return "MECH"
        case .optical:    return "OPT"
        case .symmetry:   return "SYM"
        case .structural: return "STR"
        }
    }

    // MARK: Regions pane

    private var regionsPane: some View {
        RegionHeatmapView(
            regionSeverity: regionSeverity,
            regionDomain: regionDomain,
            onSelect: { selectedRegion = $0 }
        )
    }

    // MARK: Notes pane

    private var notesPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("CLINICIAN NOTES").sectionHeaderStyle()
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Notes for this visit (no PII).")
                            .font(Type.body)
                            .foregroundStyle(Theme.inkMuted)
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 160)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .font(Type.body)
                        .foregroundStyle(Theme.ink)
                }
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

                if !pins.isEmpty {
                    Text("ANNOTATION PINS").sectionHeaderStyle()
                    VStack(spacing: 6) {
                        ForEach(pins) { pin in
                            HStack(alignment: .top, spacing: 12) {
                                if let d = pin.domain {
                                    SeverityDot(domain: d, severity: pin.severity ?? .moderate, size: 10)
                                        .padding(.top, 4)
                                } else {
                                    Circle().fill(Theme.ink).frame(width: 10, height: 10).padding(.top, 4)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pin.label)
                                        .font(Type.body)
                                        .foregroundStyle(Theme.ink)
                                    HStack(spacing: 6) {
                                        if let d = pin.domain { DomainBadge(domain: d) }
                                        Text(pin.createdAt, style: .relative)
                                            .font(Type.caption)
                                            .foregroundStyle(Theme.inkMuted)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                        }
                    }
                } else {
                    Button {
                        showingAnnotations = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add annotation pin")
                        }
                        .foregroundStyle(Theme.ink)
                    }
                    .buttonStyle(.ghost)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - 3D viewer controls

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
                .foregroundStyle(Theme.ink)
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
            .foregroundStyle(Theme.ink)
            .accessibilityLabel("Reset view")
        }
    }

    // MARK: - Save sheet

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
                        let pc = PatientCase(label: label, capturedFace: face,
                                             metricResults: results, notes: notes)
                        store.save(pc)
                        showingSaveSheet = false
                        dismiss()
                    }
                    .disabled(saveLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - PDF export

    @MainActor
    private func exportPDF() {
        guard let c = existingCase, let p = c.patient else { return }
        let snapshot = renderMeshSnapshot()
        guard let data = TreatmentPlanPDF.generate(
            patient: p, visit: c, meshSnapshot: snapshot
        ) else { return }
        let stamp = ISO8601DateFormatter().string(from: c.createdAt)
            .prefix(10)
        let name = "FaceMap_\(p.code)_\(c.label)_\(stamp)"
        pdfShareItem = PDFShareItem.write(data, suggestedName: name)
    }

    /// Snapshot the live mesh viewport into a UIImage. Falls back to a coloured
    /// placeholder if the controller hasn't attached an entity yet.
    private func renderMeshSnapshot() -> UIImage? {
        // Render a SwiftUI view that hosts the mesh into an image. We intentionally
        // re-instantiate so the viewport runs even when off-screen.
        let view = FaceMeshOverlay(
            face: face,
            regionSeverity: regionSeverity,
            regionDomain: regionDomain,
            controller: FaceMeshController()
        )
        .frame(width: 600, height: 400)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }

    // MARK: - Value formatting

    private func formatValue(_ r: MetricResult) -> String {
        if r.value.isNaN { return r.notes ?? "Unavailable" }
        switch r.metricId {
        case CanthalTiltMetric.id:
            return String(format: "min %.1f° (target %.0f–%.0f°)", r.value, r.target.lowerBound, r.target.upperBound)
        case FacialThirdsMetric.id, FacialFifthsMetric.id:
            return String(format: "worst deviation %.1f%% (target ≤ %.0f%%)", r.value * 100, r.target.upperBound * 100)
        case GoldenRatioMetric.id:
            return String(format: "worst |Δ from φ| %.1f%% (target ≤ %.0f%%)", r.value * 100, r.target.upperBound * 100)
        case AsymmetryMetric.id:
            return String(format: "worst pair Δ %.1f mm (target ≤ %.1f mm)",
                          r.value * 1000, r.target.upperBound * 1000)
        default:
            return String(format: "%.3f", r.value)
        }
    }
}

extension FacialRegion: Identifiable {
    var id: String { rawValue }
}
