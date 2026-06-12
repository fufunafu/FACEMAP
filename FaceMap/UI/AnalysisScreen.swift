import SwiftUI
import SwiftData

/// Overview-and-drill-in redesign (replaces the 4-pane layout).
/// - Header card (`SummaryHeader`) with thumbnail mesh, label/date, and `WheelGlyph`
/// - One `CategoryRow` per non-empty `FaceDomain`; tap pushes `DomainDetailScreen`
/// - Notes / Annotation pins entry rows present sheets
/// - Toolbar: visit actions (export PDF, move to patient) for saved cases,
///   calibrate, and Save for unsaved captures
struct AnalysisScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: CaseStore

    /// Full set of poses for this visit. The pose-switcher chooses which one drives
    /// the mesh + metrics + construction overlays. Single-pose callers wrap a single
    /// `CapturedFace` in `MultiPoseCapture(frontal:)`.
    let multiPose: MultiPoseCapture
    /// When opened from a stored case, edits go back to that case.
    var existingCase: PatientCase? = nil
    /// Patient this capture session was started for (threaded from
    /// `PatientDetailScreen` → `CaptureScreen`). When present, the save sheet
    /// pre-fills and locks the patient so the visit lands in their timeline.
    var patient: Patient? = nil

    @State private var activePose: CapturePose = .frontal

    /// Currently-displayed face — driven by `activePose`. All downstream UI consumes this.
    private var face: CapturedFace { multiPose.face(for: activePose) }

    init(multiPose: MultiPoseCapture, existingCase: PatientCase? = nil, patient: Patient? = nil) {
        self.multiPose = multiPose
        self.existingCase = existingCase
        self.patient = patient
    }

    /// Convenience for legacy / single-pose callers (saved cases that only have a
    /// frontal capture). Wraps the single face in a `MultiPoseCapture`.
    init(face: CapturedFace, existingCase: PatientCase? = nil, patient: Patient? = nil) {
        self.multiPose = MultiPoseCapture(frontal: face)
        self.existingCase = existingCase
        self.patient = patient
    }

    @State private var results: [MetricResult] = []
    /// True while metrics are being (re)computed — drives the "Analyzing…"
    /// placeholder on first run and dims stale findings on pose switches.
    @State private var isEvaluating = false
    @State private var showingSaveSheet = false
    @State private var notes: String = ""
    @State private var notesLoaded = false
    @State private var notesSaveTask: Task<Void, Never>?
    @State private var pins: [AnnotationPin] = []
    @State private var pinsLoaded = false
    @State private var showingAnnotations = false
    @State private var showingNotes = false
    @State private var showingFullscreenMesh = false
    @State private var pdfShareItem: PDFShareItem?
    @State private var isExportingPDF = false
    @State private var showingPDFError = false

    // Save-sheet state
    @State private var savePatientID: UUID?
    @State private var saveNewPatientMode = false
    @State private var saveNewPatientCode = ""
    @State private var visitLabel = ""
    @State private var showingSaveError = false

    // Re-bind ("Move to patient…") state
    @State private var showingMoveSheet = false

    private let notesCharLimit = 20_000

    /// A degenerate mesh (decode failure or far too few vertices) can't be analyzed
    /// or meaningfully saved.
    private var captureInvalid: Bool { face.vertexCount < 100 }

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

                    if multiPose.availablePoses.count > 1 {
                        posePicker
                            .padding(.horizontal, 16)
                    }

                    findingsSection

                    moreSection

                    DisclaimerBanner()
                        .padding(.top, 6)
                }
                .padding(.bottom, 16)
            }

            if isExportingPDF { exportingOverlay }
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
                    store.persist("save annotations")
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let c = existingCase {
                PatientPickerSheet(title: "Move to patient", currentPatient: c.patient) { target in
                    store.reassign(c, to: target)
                }
                .environmentObject(store)
            }
        }
        .sheet(item: $pdfShareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert("Could not generate the PDF for this visit", isPresented: $showingPDFError) {
            Button("OK", role: .cancel) {}
        }
        .onChange(of: activePose) { _, _ in
            // Re-evaluate metrics against the newly-selected pose so the findings list
            // and construction overlays reflect what's on screen.
            reevaluate()
        }
        .task {
            reevaluate()
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
            if newValue.count > notesCharLimit {
                notes = String(newValue.prefix(notesCharLimit))
                return
            }
            scheduleNotesSave()
        }
        .onDisappear { flushNotes() }
    }

    // MARK: - Metric evaluation

    /// Recomputes the metric set for the active pose. Two-phase so the UI can show
    /// the "Analyzing…" placeholder / dim stale findings while it runs.
    private func reevaluate() {
        guard !captureInvalid else {
            results = []
            isEvaluating = false
            return
        }
        isEvaluating = true
        let snapshot = face
        DispatchQueue.main.async {
            results = MetricRegistry.defaultRegistry()
                .evaluateAll(on: AnalyzableFace(snapshot))
            isEvaluating = false
        }
    }

    // MARK: - Pose picker (shown when this case has more than one pose)

    private var posePicker: some View {
        HStack(spacing: 8) {
            ForEach(multiPose.availablePoses) { pose in
                Button {
                    if activePose != pose { activePose = pose }
                } label: {
                    Text(pose.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(pose == activePose ? Theme.canvas : Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(pose == activePose ? Theme.ink : Theme.surface)
                        )
                        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Findings

    @ViewBuilder
    private var findingsSection: some View {
        if captureInvalid {
            invalidCaptureCard
        } else if results.isEmpty && isEvaluating {
            analyzingCard
        } else if !results.isEmpty {
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
            // Dim stale findings while a pose-switch recompute is in flight.
            .opacity(isEvaluating ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.15), value: isEvaluating)
        }
    }

    private var analyzingCard: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Theme.ink)
            Text("Analyzing…")
                .font(Type.body)
                .foregroundStyle(Theme.inkDim)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var invalidCaptureCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(Theme.inkDim)
            Text("Capture invalid — please recapture")
                .font(Type.body.weight(.medium))
                .foregroundStyle(Theme.ink)
            Text("The captured mesh has too few vertices to analyze or save.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .padding(.horizontal, 16)
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
        return "No \(joined) metrics for this capture."
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

    // MARK: - Notes persistence (debounced)

    /// Debounces the per-keystroke notes save; `flushNotes` runs on sheet dismiss
    /// so nothing is lost if the user closes the sheet inside the debounce window.
    private func scheduleNotesSave() {
        guard existingCase != nil else { return }
        notesSaveTask?.cancel()
        notesSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            flushNotes()
        }
    }

    private func flushNotes() {
        notesSaveTask?.cancel()
        notesSaveTask = nil
        guard let c = existingCase, (c.notes ?? "") != notes else { return }
        c.notes = notes
        store.persist("save notes")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if existingCase != nil {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { exportPDF() } label: {
                        Label("Export plan", systemImage: "square.and.arrow.up")
                    }
                    Button { showingMoveSheet = true } label: {
                        Label("Move to patient…", systemImage: "person.crop.circle.badge.checkmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .foregroundStyle(Theme.ink)
                .accessibilityLabel("Visit actions")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                CalibrationScreen(face: face) {
                    reevaluate()
                }
            } label: {
                Image(systemName: "scope")
                    .accessibilityLabel("Calibrate landmarks")
            }
            .foregroundStyle(Theme.ink)
        }
        if existingCase == nil {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { prepareSaveSheet() }
                    .foregroundStyle(Theme.ink)
                    .disabled(captureInvalid)
            }
        }
    }

    // MARK: - Save sheet

    private func prepareSaveSheet() {
        savePatientID = patient?.id
        saveNewPatientMode = false
        saveNewPatientCode = ""
        visitLabel = store.suggestedVisitLabel(for: patient)
        showingSaveSheet = true
    }

    private var activePatients: [Patient] {
        store.activePatients()
    }

    private var trimmedNewPatientCode: String {
        saveNewPatientCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var newPatientCodeInUse: Bool {
        store.isCodeInUse(trimmedNewPatientCode)
    }

    private var saveDisabled: Bool {
        if captureInvalid { return true }
        if saveNewPatientMode {
            return trimmedNewPatientCode.isEmpty || newPatientCodeInUse
        }
        return false
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section {
                    if let locked = patient {
                        HStack {
                            Text(locked.code)
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: "lock")
                                .foregroundStyle(Theme.inkMuted)
                        }
                    } else if saveNewPatientMode {
                        TextField("New patient code", text: $saveNewPatientCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        if newPatientCodeInUse {
                            Text("This code is already in use")
                                .font(Type.caption)
                                .foregroundStyle(warningAmber)
                        }
                        Button("Choose an existing patient instead") {
                            saveNewPatientMode = false
                            saveNewPatientCode = ""
                        }
                    } else {
                        Picker("Patient", selection: $savePatientID) {
                            Text("Unassigned").tag(UUID?.none)
                            ForEach(activePatients, id: \.id) { p in
                                Text(p.code).tag(UUID?.some(p.id))
                            }
                        }
                        Button("New patient…") { saveNewPatientMode = true }
                    }
                } header: {
                    Text("Patient")
                } footer: {
                    Text("Pseudonymous codes only (e.g. \"P-014\"). Unassigned visits can be moved to a patient later.")
                }

                Section {
                    TextField("Visit label", text: $visitLabel)
                } header: {
                    Text("Visit label")
                } footer: {
                    Text("Optional — e.g. \"Visit 2 — pre-treatment\". Defaults to \"\(store.suggestedVisitLabel(for: selectedSavePatient))\".")
                }
            }
            .navigationTitle("Save visit")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: savePatientID) { _, _ in
                visitLabel = store.suggestedVisitLabel(for: selectedSavePatient)
            }
            .alert("Could not save this visit — try again", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { performSave() }
                        .disabled(saveDisabled)
                }
            }
        }
    }

    // TODO: migrate to Theme.warning token
    private let warningAmber = Color(hex: 0xC77D0A)

    /// The patient currently selected in the save sheet (nil = Unassigned).
    private var selectedSavePatient: Patient? {
        if let bound = patient { return bound }
        guard let id = savePatientID else { return nil }
        return activePatients.first { $0.id == id }
    }

    private func performSave() {
        guard !captureInvalid else { return }

        let resolvedPatient: Patient?
        if let bound = patient {
            resolvedPatient = bound
        } else if saveNewPatientMode {
            guard !trimmedNewPatientCode.isEmpty, !newPatientCodeInUse else { return }
            resolvedPatient = store.createPatient(code: trimmedNewPatientCode)
        } else {
            resolvedPatient = selectedSavePatient
        }

        let trimmedLabel = visitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = trimmedLabel.isEmpty
            ? store.suggestedVisitLabel(for: resolvedPatient)
            : trimmedLabel

        // Frontal pose is the primary `capturedFace`; the obliques get
        // saved to dedicated fields so the case round-trips with all three.
        let pc = PatientCase(
            label: label,
            capturedFace: multiPose.frontal,
            metricResults: results,
            patient: resolvedPatient,
            notes: notes.isEmpty ? nil : notes,
            obliqueL: multiPose.obliqueL,
            obliqueR: multiPose.obliqueR
        )
        switch store.save(pc) {
        case .success:
            showingSaveSheet = false
            dismiss()
        case .failure:
            // Keep the sheet open; the sheet-local alert is more specific than the
            // store-wide one, so consume the published error.
            store.lastSaveError = nil
            showingSaveError = true
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

                        Text("\(notes.count) / \(notesCharLimit) characters")
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        flushNotes()
                        showingNotes = false
                    }
                    .foregroundStyle(Theme.ink)
                }
            }
            .onDisappear { flushNotes() }
        }
    }

    // MARK: - PDF export

    private var exportingOverlay: some View {
        ZStack {
            Theme.canvas.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().scaleEffect(1.2).tint(Theme.ink)
                Text("Preparing PDF…")
                    .font(Type.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    @MainActor
    private func exportPDF() {
        guard let c = existingCase else { return }
        guard let p = c.patient else {
            showingPDFError = true
            return
        }
        isExportingPDF = true
        // Defer one runloop turn so the progress overlay has a chance to render
        // before the (synchronous) renderer work starts.
        DispatchQueue.main.async {
            defer { isExportingPDF = false }
            let snapshot = renderMeshSnapshot()
            guard let data = TreatmentPlanPDF.generate(
                patient: p, visit: c, meshSnapshot: snapshot
            ) else {
                showingPDFError = true
                return
            }
            let stamp = ISO8601DateFormatter().string(from: c.createdAt).prefix(10)
            let name = "FaceMap_\(p.code)_\(c.label)_\(stamp)"
            guard let item = PDFShareItem.write(data, suggestedName: name) else {
                showingPDFError = true
                return
            }
            pdfShareItem = item
        }
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

// MARK: - Patient picker (re-bind)

/// Patient chooser used by "Move to patient…" re-bind flows — from a saved case's
/// toolbar here and from visit rows in `PatientDetailScreen`. Lists active patients
/// and offers inline creation of a new one.
struct PatientPickerSheet: View {
    @EnvironmentObject var store: CaseStore
    @Environment(\.dismiss) private var dismiss

    let title: String
    var currentPatient: Patient? = nil
    let onSelect: (Patient) -> Void

    @State private var creatingNew = false
    @State private var newCode = ""

    // TODO: migrate to Theme.warning token
    private let warningAmber = Color(hex: 0xC77D0A)

    private var trimmedNewCode: String {
        newCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var newCodeInUse: Bool {
        store.isCodeInUse(trimmedNewCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(store.activePatients(), id: \.id) { p in
                        Button {
                            onSelect(p)
                            dismiss()
                        } label: {
                            HStack {
                                Text(p.code)
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                if p.id == currentPatient?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.inkDim)
                                }
                            }
                        }
                        .disabled(p.id == currentPatient?.id)
                    }
                } header: {
                    Text("Patients")
                } footer: {
                    Text("Pseudonymous codes only. No PII.")
                }

                Section {
                    if creatingNew {
                        TextField("New patient code", text: $newCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        if newCodeInUse {
                            Text("This code is already in use")
                                .font(Type.caption)
                                .foregroundStyle(warningAmber)
                        }
                        Button("Create and move") {
                            guard !trimmedNewCode.isEmpty, !newCodeInUse else { return }
                            let p = store.createPatient(code: trimmedNewCode)
                            onSelect(p)
                            dismiss()
                        }
                        .disabled(trimmedNewCode.isEmpty || newCodeInUse)
                    } else {
                        Button("New patient…") { creatingNew = true }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
