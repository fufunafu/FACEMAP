import SwiftUI
import SwiftData

/// Root of the Patients tab. Pseudonymous codes only; no PII fields.
struct PatientListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var store: CaseStore

    @Query(filter: #Predicate<Patient> { $0.archivedAt == nil },
           sort: \Patient.createdAt, order: .reverse)
    private var patients: [Patient]

    @Query(filter: #Predicate<Patient> { $0.archivedAt != nil },
           sort: \Patient.createdAt, order: .reverse)
    private var archivedPatients: [Patient]

    @State private var search = ""
    @State private var showingNewPatient = false
    @State private var newPatientCode = ""
    @State private var patientToArchive: Patient?
    @State private var showingArchiveConfirm = false
    @State private var patientToDelete: Patient?
    @State private var showingDeleteConfirm = false

    // TODO: migrate to Theme.warning token
    private let warningAmber = Color(hex: 0xC77D0A)

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if patients.isEmpty && archivedPatients.isEmpty {
                emptyState
            } else {
                patientList
            }
        }
        .navigationTitle("Patients")
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BrandMark(.small)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newPatientCode = ""
                    showingNewPatient = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .navigationDestination(for: Patient.self) { p in
            PatientDetailScreen(patient: p)
        }
        .sheet(isPresented: $showingNewPatient) { newPatientSheet }
        .confirmationDialog(
            "Archive this patient?",
            isPresented: $showingArchiveConfirm,
            titleVisibility: .visible,
            presenting: patientToArchive
        ) { p in
            Button("Archive \(p.code)") {
                store.archive(p)
                patientToArchive = nil
            }
            Button("Cancel", role: .cancel) { patientToArchive = nil }
        } message: { _ in
            Text("Archived patients are hidden from the main list. You can unarchive them — or delete them permanently — from the Archived section.")
        }
        .confirmationDialog(
            "Permanently delete this patient?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible,
            presenting: patientToDelete
        ) { p in
            Button("Delete \(p.code) and all visits", role: .destructive) {
                store.deletePatient(p)
                patientToDelete = nil
            }
            Button("Cancel", role: .cancel) { patientToDelete = nil }
        } message: { _ in
            Text("This permanently deletes the patient and every visit captured for them. This cannot be undone.")
        }
    }

    // MARK: - List

    private var patientList: some View {
        List {
            if !filtered.isEmpty {
                Section {
                    ForEach(filtered) { p in
                        NavigationLink(value: p) {
                            PatientListRow(patient: p, matchSubtitle: matchingVisitSubtitle(for: p))
                        }
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                patientToArchive = p
                                showingArchiveConfirm = true
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(Theme.inkDim)
                        }
                    }
                } header: {
                    Text("Patients").sectionHeaderStyle()
                } footer: {
                    Text("Tap a patient to see their visit timeline. Swipe a row to archive.")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }

            if !filteredArchived.isEmpty {
                Section {
                    ForEach(filteredArchived) { p in
                        NavigationLink(value: p) {
                            PatientListRow(patient: p, matchSubtitle: matchingVisitSubtitle(for: p))
                                .opacity(0.6)
                        }
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                patientToDelete = p
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                store.unarchive(p)
                            } label: {
                                Label("Unarchive", systemImage: "tray.and.arrow.up")
                            }
                            .tint(Theme.inkDim)
                        }
                        .contextMenu {
                            Button {
                                store.unarchive(p)
                            } label: {
                                Label("Unarchive", systemImage: "tray.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                patientToDelete = p
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete permanently", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Archived").sectionHeaderStyle()
                } footer: {
                    Text("Swipe to unarchive, or to delete permanently.")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }

            if filtered.isEmpty && filteredArchived.isEmpty {
                Section {
                    noResultsRow
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
    }

    private var noResultsRow: some View {
        VStack(spacing: 6) {
            Text("No patients match \"\(trimmedSearch)\"")
                .font(Type.body)
                .foregroundStyle(Theme.inkDim)
            Text("Search matches patient codes, visit labels, and visit notes.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.vertical, 24)
    }

    // MARK: - Search

    private var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filtered: [Patient] {
        filterPatients(patients)
    }

    private var filteredArchived: [Patient] {
        // Archived patients only appear while browsing (no query) or when they match.
        filterPatients(archivedPatients)
    }

    /// Matches the query against the patient code, visit labels, and visit notes.
    private func filterPatients(_ source: [Patient]) -> [Patient] {
        guard !trimmedSearch.isEmpty else { return source }
        return source.filter { p in
            p.code.localizedCaseInsensitiveContains(trimmedSearch)
                || matchingVisit(for: p) != nil
        }
    }

    /// First visit whose label or notes match the current query.
    private func matchingVisit(for p: Patient) -> PatientCase? {
        guard !trimmedSearch.isEmpty else { return nil }
        return p.sortedCases.first { c in
            c.label.localizedCaseInsensitiveContains(trimmedSearch)
                || (c.notes ?? "").localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    /// Subtitle shown under a row when the query matched a visit rather than the code.
    private func matchingVisitSubtitle(for p: Patient) -> String? {
        guard let hit = matchingVisit(for: p) else { return nil }
        return "Matches \(hit.label)"
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            BrandMark(.medium)
            VStack(spacing: 8) {
                Text("No patients yet")
                    .font(Type.titleLarge)
                    .foregroundStyle(Theme.ink)
                Text("Add a patient to start a visit timeline. Cases captured ad-hoc go into an Unassigned bucket you can re-bind later.")
                    .font(Type.callout)
                    .foregroundStyle(Theme.inkDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                newPatientCode = ""
                showingNewPatient = true
            } label: {
                Text("Add patient")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 48)
            Spacer()
        }
    }

    // MARK: - New patient sheet

    private var trimmedNewCode: String {
        newPatientCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var newCodeInUse: Bool {
        store.isCodeInUse(trimmedNewCode)
    }

    private var newPatientSheet: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Patient code", text: $newPatientCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        if newCodeInUse {
                            Text("This code is already in use")
                                .font(Type.caption)
                                .foregroundStyle(warningAmber)
                        }
                    } footer: {
                        Text("Use a pseudonym such as \"P-014\". No identifying information.")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Theme.canvas)
            }
            .navigationTitle("New patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewPatient = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !trimmedNewCode.isEmpty, !newCodeInUse else { return }
                        _ = store.createPatient(code: trimmedNewCode)
                        showingNewPatient = false
                    }
                    .disabled(trimmedNewCode.isEmpty || newCodeInUse)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Row

private struct PatientListRow: View {
    let patient: Patient
    var matchSubtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.code)
                    .font(Type.metricName)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    Text(visitsLabel)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkDim)
                    if let last = patient.sortedCases.first {
                        Text("·").foregroundStyle(Theme.inkMuted)
                        Text(last.createdAt, style: .date)
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkDim)
                    }
                }
                if let matchSubtitle {
                    Text(matchSubtitle)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            Spacer()
            sparkline
        }
        .padding(.vertical, 4)
    }

    private var visitsLabel: String {
        let n = patient.cases.count
        return n == 1 ? "1 visit" : "\(n) visits"
    }

    /// 3-dot mini sparkline of severity across the latest visits — rightmost is most recent.
    private var sparkline: some View {
        let recent = Array(patient.sortedCases.prefix(3).reversed())
        return HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                if i < recent.count {
                    let c = recent[i]
                    let dom = dominantDomain(of: c)
                    let sev = worstSeverity(of: c)
                    SeverityDot(domain: dom, severity: sev, size: 8)
                } else {
                    Circle()
                        .stroke(Theme.hairline, lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private func worstSeverity(of c: PatientCase) -> MetricResult.Severity {
        let order: [MetricResult.Severity] = [.normal, .mild, .moderate, .significant]
        var worst: MetricResult.Severity = .normal
        for r in c.metricResults {
            if (order.firstIndex(of: r.severity) ?? 0) > (order.firstIndex(of: worst) ?? 0) {
                worst = r.severity
            }
        }
        return worst
    }

    private func dominantDomain(of c: PatientCase) -> FaceDomain {
        // The domain owning the worst-severity metric in the case.
        let order: [MetricResult.Severity] = [.normal, .mild, .moderate, .significant]
        var best: (MetricResult.Severity, FaceDomain) = (.normal, .symmetry)
        for r in c.metricResults {
            if (order.firstIndex(of: r.severity) ?? 0) > (order.firstIndex(of: best.0) ?? 0) {
                best = (r.severity, r.domain)
            }
        }
        return best.1
    }
}
