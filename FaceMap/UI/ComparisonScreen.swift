import SwiftUI

/// Side-by-side comparison of two visits for the same patient. The left column always
/// shows the older visit (Visit A); the right shows the newer (Visit B). A delta table
/// underneath shows how each metric changed; arrow direction encodes "got worse / better".
struct ComparisonScreen: View {
    let patient: Patient
    let visitA: PatientCase   // older
    let visitB: PatientCase   // newer

    @StateObject private var meshA = FaceMeshController()
    @StateObject private var meshB = FaceMeshController()
    @State private var syncRotation = true

    private var resultsA: [MetricResult] { visitA.metricResults }
    private var resultsB: [MetricResult] { visitB.metricResults }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    meshRow
                    wheelRow
                    deltaSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $syncRotation) {
                    Image(systemName: syncRotation ? "lock.fill" : "lock.open")
                }
                .toggleStyle(.button)
                .foregroundStyle(Theme.ink)
                .accessibilityLabel("Sync mesh rotation")
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PATIENT").sectionHeaderStyle()
            HStack(alignment: .firstTextBaseline) {
                Text(patient.code).font(Type.titleLarge).foregroundStyle(Theme.ink)
                Spacer()
                Text(daysBetween)
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
            }
        }
    }

    private var daysBetween: String {
        let days = Calendar.current.dateComponents(
            [.day], from: visitA.createdAt, to: visitB.createdAt
        ).day ?? 0
        return "\(days) day\(days == 1 ? "" : "s") between visits"
    }

    // MARK: - Mesh row

    private var meshRow: some View {
        HStack(spacing: 12) {
            meshColumn(face: visitA.capturedFace, label: visitA.label,
                       date: visitA.createdAt, controller: meshA, results: resultsA, side: "A")
            meshColumn(face: visitB.capturedFace, label: visitB.label,
                       date: visitB.createdAt, controller: meshB, results: resultsB, side: "B")
        }
    }

    private func meshColumn(face: CapturedFace?, label: String, date: Date,
                            controller: FaceMeshController,
                            results: [MetricResult], side: String) -> some View {
        let regSeverity = results.flaggedRegionsBySeverity
        let regDomain   = results.regionDomainsByWorstSeverity
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VISIT \(side)").sectionHeaderStyle()
                Spacer()
                Text(date, style: .date)
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
            }
            if let face {
                FaceMeshOverlay(
                    face: face,
                    regionSeverity: regSeverity,
                    regionDomain: regDomain,
                    controller: controller
                )
                .frame(height: 200)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            } else {
                placeholderMesh
            }
            Text(label)
                .font(Type.callout)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholderMesh: some View {
        ZStack {
            Theme.surface
            Text("Mesh unreadable").font(Type.caption).foregroundStyle(Theme.inkMuted)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    // MARK: - Wheel row

    private var wheelRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHEELS").sectionHeaderStyle()
            HStack(spacing: 12) {
                AestheticWheel(results: resultsA, diameter: 150, showsLabels: false)
                    .frame(maxWidth: .infinity)
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.inkDim)
                AestheticWheel(results: resultsB, diameter: 150, showsLabels: false)
                    .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        }
    }

    // MARK: - Delta table

    private var deltaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHANGES").sectionHeaderStyle()
            VStack(spacing: 6) {
                ForEach(deltas, id: \.metricId) { d in
                    deltaRow(d)
                }
            }
        }
    }

    private struct Delta: Identifiable {
        var id: String { metricId }
        let metricId: String
        let metricName: String
        let domain: FaceDomain
        let valueA: Double
        let valueB: Double
        let signedChange: Double
        let severityA: MetricResult.Severity
        let severityB: MetricResult.Severity
    }

    private var deltas: [Delta] {
        let mapA = Dictionary(uniqueKeysWithValues: resultsA.map { ($0.metricId, $0) })
        let mapB = Dictionary(uniqueKeysWithValues: resultsB.map { ($0.metricId, $0) })
        let ids = Set(mapA.keys).union(mapB.keys).sorted()
        return ids.compactMap { id in
            let a = mapA[id]
            let b = mapB[id]
            let domain = a?.domain ?? b?.domain ?? .symmetry
            return Delta(
                metricId: id,
                metricName: a?.metricName ?? b?.metricName ?? id,
                domain: domain,
                valueA: a?.value ?? .nan,
                valueB: b?.value ?? .nan,
                signedChange: (b?.value ?? 0) - (a?.value ?? 0),
                severityA: a?.severity ?? .normal,
                severityB: b?.severity ?? .normal
            )
        }
    }

    private func deltaRow(_ d: Delta) -> some View {
        let aImproved = d.severityB.ringIndex < d.severityA.ringIndex
        let aWorsened = d.severityB.ringIndex > d.severityA.ringIndex
        let arrow: String
        let arrowColor: Color
        switch (aImproved, aWorsened) {
        case (true, _):  arrow = "arrow.down.right";  arrowColor = Theme.ink
        case (_, true):  arrow = "arrow.up.right";    arrowColor = d.domain.hue
        default:         arrow = "arrow.right";       arrowColor = Theme.inkMuted
        }

        return HStack(spacing: 12) {
            SeverityDot(domain: d.domain, severity: d.severityB, size: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(d.metricName)
                        .font(Type.metricName)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    DomainBadge(domain: d.domain)
                }
                HStack(spacing: 6) {
                    Text(formatValue(d.valueA, id: d.metricId))
                        .font(Type.caption.monospacedDigit())
                        .foregroundStyle(Theme.inkDim)
                    Image(systemName: arrow).font(.system(size: 11))
                        .foregroundStyle(arrowColor)
                    Text(formatValue(d.valueB, id: d.metricId))
                        .font(Type.caption.monospacedDigit())
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(severityChangeLabel(d))
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func formatValue(_ v: Double, id: String) -> String {
        if v.isNaN { return "—" }
        switch id {
        case CanthalTiltMetric.id: return String(format: "%.1f°", v)
        case AsymmetryMetric.id:   return String(format: "%.1f mm", v * 1000)
        default:                   return String(format: "%.1f%%", v * 100)
        }
    }

    private func severityChangeLabel(_ d: Delta) -> String {
        let a = d.severityA.rawValue.capitalized
        let b = d.severityB.rawValue.capitalized
        return a == b ? a : "\(a) → \(b)"
    }
}
