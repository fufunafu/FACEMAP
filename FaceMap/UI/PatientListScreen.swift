import SwiftUI
import SwiftData

/// Root of the Patients tab. Pseudonymous codes only; no PII fields.
struct PatientListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var store: CaseStore

    @Query(filter: #Predicate<Patient> { $0.archivedAt == nil },
           sort: \Patient.createdAt, order: .reverse)
    private var patients: [Patient]

    @State private var search = ""
    @State private var showingNewPatient = false
    @State private var newPatientCode = ""

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if patients.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        ForEach(filtered) { p in
                            NavigationLink(value: p) {
                                PatientListRow(patient: p)
                            }
                            .listRowBackground(Theme.surface)
                        }
                        .onDelete { indexes in
                            for i in indexes { store.archive(filtered[i]) }
                        }
                    } header: {
                        Text("Patients").sectionHeaderStyle()
                    } footer: {
                        Text("Tap a patient to see their visit timeline. Swipe a row to archive.")
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkMuted)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.canvas)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
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
    }

    private var filtered: [Patient] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return patients }
        return patients.filter { $0.code.localizedCaseInsensitiveContains(trimmed) }
    }

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

    private var newPatientSheet: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Patient code", text: $newPatientCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
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
                        _ = store.createPatient(code: newPatientCode)
                        showingNewPatient = false
                    }
                    .disabled(newPatientCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Row

private struct PatientListRow: View {
    let patient: Patient

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
