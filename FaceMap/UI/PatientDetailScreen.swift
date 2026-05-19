import SwiftUI
import SwiftData
import Charts

/// Visit timeline for a single patient. Shows a wheel of the latest visit, a per-domain trend
/// chart across all visits, and a list of visits as `ThumbnailCard`-style rows.
struct PatientDetailScreen: View {
    @Bindable var patient: Patient
    @EnvironmentObject var store: CaseStore

    @State private var renameOpen = false
    @State private var draftCode = ""
    @State private var multiSelectMode = false
    @State private var selectedForCompare: Set<UUID> = []
    @State private var showCompare = false

    private var sortedCases: [PatientCase] { patient.sortedCases }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if let latest = sortedCases.first {
                        latestVisitCard(latest)
                        trendStrip
                    } else {
                        addFirstVisitCard
                    }
                    visitsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(patient.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename code") {
                        draftCode = patient.code
                        renameOpen = true
                    }
                    if !sortedCases.isEmpty {
                        Button(multiSelectMode ? "Done" : "Compare visits") {
                            multiSelectMode.toggle()
                            selectedForCompare.removeAll()
                        }
                    }
                    Divider()
                    Button("Archive patient", role: .destructive) {
                        store.archive(patient)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .sheet(isPresented: $renameOpen) { renameSheet }
        .navigationDestination(isPresented: $showCompare) {
            if let pair = selectedComparePair {
                ComparisonScreen(patient: patient, visitA: pair.0, visitB: pair.1)
            } else {
                Text("Pick exactly two visits to compare.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PATIENT").sectionHeaderStyle()
            HStack(alignment: .firstTextBaseline) {
                Text(patient.code)
                    .font(Type.displayMedium)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(patient.cases.count) visit\(patient.cases.count == 1 ? "" : "s")")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
            }

            NavigationLink {
                CaptureScreen()
                    .environmentObject(store)
                    .onDisappear { /* binding handled in CaptureScreen save */ }
            } label: {
                Text("Add visit")
            }
            .buttonStyle(.primary)
            .padding(.top, 4)
        }
    }

    // MARK: - Latest visit card

    private func latestVisitCard(_ c: PatientCase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LATEST VISIT").sectionHeaderStyle()
            HStack(alignment: .top, spacing: 12) {
                AestheticWheel(results: c.metricResults, diameter: 200, showsLabels: true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(c.label)
                        .font(Type.titleLarge)
                        .foregroundStyle(Theme.ink)
                    Text(c.createdAt, style: .date)
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkDim)
                    Text(summary(of: c))
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.top, 4)
                    Spacer()
                    if let face = c.capturedFace {
                        NavigationLink {
                            AnalysisScreen(
                            multiPose: c.multiPoseCapture ?? MultiPoseCapture(frontal: face),
                            existingCase: c
                        )
                        } label: {
                            Text("Open")
                        }
                        .buttonStyle(.ghost)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        }
    }

    private var addFirstVisitCard: some View {
        VStack(spacing: 8) {
            Text("No visits yet for this patient.")
                .font(Type.body)
                .foregroundStyle(Theme.inkDim)
            Text("Use “Add visit” above to capture one.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    // MARK: - Trend strip (per-domain line chart across visits)

    private var trendStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRENDS").sectionHeaderStyle()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FaceDomain.allCases) { d in
                        domainTrendCard(d)
                    }
                }
            }
        }
    }

    private func domainTrendCard(_ d: FaceDomain) -> some View {
        let series = trendSeries(for: d)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(d.hue).frame(width: 6, height: 6)
                Text(d.displayName)
                    .font(Type.captionStrong)
                    .foregroundStyle(Theme.ink)
            }
            if series.isEmpty {
                Text("Coming soon")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 140, height: 56, alignment: .center)
            } else {
                Chart {
                    ForEach(series) { p in
                        LineMark(x: .value("Visit", p.index),
                                 y: .value("Severity", p.severityScore))
                            .foregroundStyle(d.hue)
                        PointMark(x: .value("Visit", p.index),
                                  y: .value("Severity", p.severityScore))
                            .foregroundStyle(d.hue)
                    }
                }
                .chartYScale(domain: 0...3)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 140, height: 56)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let index: Int
        let severityScore: Double
    }

    /// Per-visit (oldest → newest) maximum severity ringIndex among metrics in this domain.
    private func trendSeries(for domain: FaceDomain) -> [TrendPoint] {
        let chronological = patient.sortedCases.reversed()
        var points: [TrendPoint] = []
        for (i, c) in chronological.enumerated() {
            let inDomain = c.metricResults.filter { $0.domain == domain }
            guard !inDomain.isEmpty else { continue }
            let worst = inDomain.map(\.severity.ringIndex).max() ?? 0
            points.append(TrendPoint(index: i, severityScore: Double(worst)))
        }
        return points
    }

    // MARK: - Visits list

    private var visitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VISITS").sectionHeaderStyle()
                Spacer()
                if multiSelectMode {
                    Button("Compare \(selectedForCompare.count)/2") {
                        if selectedForCompare.count == 2 { showCompare = true }
                    }
                    .disabled(selectedForCompare.count != 2)
                    .font(Type.captionStrong)
                    .foregroundStyle(selectedForCompare.count == 2 ? Theme.ink : Theme.inkMuted)
                }
            }
            VStack(spacing: 8) {
                ForEach(sortedCases, id: \.id) { c in
                    visitRow(c)
                }
            }
        }
    }

    private func visitRow(_ c: PatientCase) -> some View {
        Group {
            if multiSelectMode {
                Button {
                    toggleSelection(of: c)
                } label: {
                    visitRowContent(c, isSelected: selectedForCompare.contains(c.id))
                }
                .buttonStyle(.plain)
            } else if let face = c.capturedFace {
                NavigationLink {
                    AnalysisScreen(
                            multiPose: c.multiPoseCapture ?? MultiPoseCapture(frontal: face),
                            existingCase: c
                        )
                } label: {
                    visitRowContent(c, isSelected: false)
                }
                .buttonStyle(.plain)
            } else {
                visitRowContent(c, isSelected: false).opacity(0.5)
            }
        }
    }

    private func visitRowContent(_ c: PatientCase, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            if multiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.ink : Theme.inkMuted)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(c.label)
                    .font(Type.metricName)
                    .foregroundStyle(Theme.ink)
                Text(c.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
                Text(summary(of: c))
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkMuted)
            }
            Spacer()
            AestheticWheel(results: c.metricResults, diameter: 64, showsLabels: false)
                .allowsHitTesting(false)
        }
        .padding(12)
        .background(isSelected ? Theme.surfaceRaised : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func toggleSelection(of c: PatientCase) {
        if selectedForCompare.contains(c.id) {
            selectedForCompare.remove(c.id)
        } else if selectedForCompare.count < 2 {
            selectedForCompare.insert(c.id)
        }
    }

    private var selectedComparePair: (PatientCase, PatientCase)? {
        let chosen = sortedCases.filter { selectedForCompare.contains($0.id) }
        guard chosen.count == 2 else { return nil }
        // Visit A = older, Visit B = newer.
        let sorted = chosen.sorted { $0.createdAt < $1.createdAt }
        return (sorted[0], sorted[1])
    }

    // MARK: - Helpers

    private func summary(of c: PatientCase) -> String {
        let flagged = c.metricResults.filter { !$0.isWithinTarget }
        if flagged.isEmpty { return "All metrics within target" }
        let worst = flagged.max { lhs, rhs in
            (lhs.severity.ringIndex) < (rhs.severity.ringIndex)
        }!
        return "\(flagged.count) flagged · worst: \(worst.metricName)"
    }

    private var renameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Patient code", text: $draftCode)
                        .textInputAutocapitalization(.characters)
                } footer: {
                    Text("Pseudonymous code only. No PII.")
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { renameOpen = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = draftCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { patient.code = trimmed }
                        renameOpen = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
