import SwiftUI
import SwiftData

/// Overview-and-drill-in redesign (replaces the 4-pane layout).
/// - Header card (`SummaryHeader`) with thumbnail mesh, label/date, and `WheelGlyph`
/// - One `CategoryRow` per non-empty `FaceDomain`; tap pushes `DomainDetailScreen`
/// - Notes / Annotation pins entry rows present sheets
/// - Toolbar (calibrate, annotations, export PDF, save) preserved verbatim
struct AnalysisScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: CaseStore

    let face: CapturedFace
    /// When opened from a stored case, edits go back to that case.
    var existingCase: PatientCase? = nil

    @State private var results: [MetricResult] = []
    @State private var saveLabel = ""
    @State private var showingSaveSheet = false
    @State private var notes: String = ""
    @State private var notesLoaded = false
    @State private var pins: [AnnotationPin] = []
    @State private var pinsLoaded = false
    @State private var showingAnnotations = false
    @State private var showingNotes = false
    @State private var showingFullscreenMesh = false
    @State private var pdfShareItem: PDFShareItem?

    private var regionSeverity: [FacialRegion: MetricResult.Severity] {
        results.flaggedRegionsBySeverity
    }

    private var regionDomain: [FacialRegion: FaceDomain] {
        results.regionDomainsByWorstSeverity
    }

    /// Domains that have at least one metric in the current registry.
    private var populatedDomains: [FaceDomain] {
        FaceDomain.allCases.filter { d in
            results.contains { $0.domain == d }
        }
    }

    /// Domains the registry doesn't (yet) cover. Rendered as a single muted footnote.
    private var unpopulatedDomains: [FaceDomain] {
        FaceDomain.allCases.filter { d in
            !results.contains { $0.domain == d }
        }
    }

    private var headerLabel: String {
        existingCase?.label ?? "Current capture"
    }

    private var visitDate: Date? {
        existingCase?.createdAt ?? face.timestamp
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    SummaryHeader(
                        face: face,
                        label: headerLabel,
                        visitDate: visitDate,
                        results: results,
                        regionSeverity: regionSeverity,
                        regionDomain: regionDomain,
                        onOpenFullscreen: { showingFullscreenMesh = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    findingsSection

                    moreSection

                    DisclaimerBanner()
                        .padding(.top, 6)
                }
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(existingCase?.label ?? "Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingSaveSheet) { saveSheet }
        .sheet(isPresented: $showingFullscreenMesh) {
            MeshFullScreen(
                face: face,
                regionSeverity: regionSeverity,
                regionDomain: regionDomain
            )
        }
        .sheet(isPresented: $showingNotes) { notesSheet }
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
            if let c = existingCase {
                c.notes = newValue
                try? store.context.save()
            }
        }
    }

    // MARK: - Findings

    @ViewBuilder
    private var findingsSection: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("FINDINGS BY DOMAIN")
                    .sectionHeaderStyle()
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    ForEach(populatedDomains) { d in
                        NavigationLink {
                            DomainDetailScreen(
                                domain: d,
                                face: face,
                                allResults: results,
                                regionSeverity: regionSeverity,
                                regionDomain: regionDomain,
                                valueFormatter: formatValue
                            )
                        } label: {
                            CategoryRow(
                                domain: d,
                                results: results.filter { $0.domain == d },
                                valueFormatter: formatValue
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                if !unpopulatedDomains.isEmpty {
                    Text(unpopulatedFootnote)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var unpopulatedFootnote: String {
        let names = unpopulatedDomains.map { $0.displayName }
        let joined: String
        switch names.count {
        case 0: return ""
        case 1: joined = names[0]
        case 2: joined = "\(names[0]) and \(names[1])"
        default: joined = names.dropLast().joined(separator: ", ") + ", and " + names.last!
        }
        return "\(joined) metrics arrive in v0.3."
    }

    // MARK: - More (notes + pins entry rows)

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MORE")
                .sectionHeaderStyle()
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                Button { showingNotes = true } label: {
                    moreRow(
                        icon: "square.and.pencil",
                        title: "Notes",
                        subtitle: notes.isEmpty ? "Add visit notes" : trimmedPreview(notes)
                    )
                }
                .buttonStyle(.plain)

                Button { showingAnnotations = true } label: {
                    moreRow(
                        icon: "mappin.and.ellipse",
                        title: "Annotation pins",
                        subtitle: pins.isEmpty ? "Drop pins on the mesh" : "\(pins.count) pin\(pins.count == 1 ? "" : "s")"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
    }

    private func moreRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Theme.ink)
                .frame(width: 28, height: 28)
                .background(Theme.surfaceRaised, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Type.metricName)
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func trimmedPreview(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        if trimmed.count > 60 {
            return String(trimmed.prefix(60)) + "…"
        }
        return trimmed
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if existingCase != nil {
            ToolbarItem(placement: .topBarTrailing) {
                Button { exportPDF() } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundStyle(Theme.ink)
                .accessibilityLabel("Export plan")
            }
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

    // MARK: - Notes sheet

    private var notesSheet: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
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
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .font(Type.body)
                                .foregroundStyle(Theme.ink)
                        }
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingNotes = false }
                        .foregroundStyle(Theme.ink)
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
        let stamp = ISO8601DateFormatter().string(from: c.createdAt).prefix(10)
        let name = "FaceMap_\(p.code)_\(c.label)_\(stamp)"
        pdfShareItem = PDFShareItem.write(data, suggestedName: name)
    }

    private func renderMeshSnapshot() -> UIImage? {
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
        case SurfaceDisplacementMetric.id:
            return String(format: "worst Z-deficit %.1f mm (target ≤ %.1f mm)",
                          r.value * 1000, r.target.upperBound * 1000)
        default:
            return String(format: "%.3f", r.value)
        }
    }
}

extension FacialRegion: Identifiable {
    var id: String { rawValue }
}
