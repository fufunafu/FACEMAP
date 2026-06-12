import SwiftUI
import UIKit

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
    @State private var regionChange: RegionChangeState = .loading

    @State private var pdfShareItem: PDFShareItem?
    @State private var cleanupItem: PDFShareItem?
    @State private var isExporting = false
    @State private var exportErrorMessage: String?
    @State private var showingExportError = false

    // Inline status colours for visit-over-visit change. Worsened must read heavier
    // than improved; facet/domain hues must never carry status meaning.
    // TODO: Theme.statusWorsened / Theme.statusImproved tokens.
    private static let worsenedInk = Color(hex: 0x9B3B2E)   // desaturated brick
    private static let improvedInk = Color(hex: 0x3E7C4F)   // desaturated green

    private var resultsA: [MetricResult] { visitA.metricResults }
    private var resultsB: [MetricResult] { visitB.metricResults }

    private enum RegionChangeState {
        case loading
        case computed([RegionProjectionDelta])
        case incompatible
    }

    private var isFullyCalibrated: Bool {
        LandmarkCalibrationStore.shared.isFullyCalibrated
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !isFullyCalibrated {
                        calibrationBanner
                    }
                    headerCard
                    meshRow
                    photoRow
                    regionChangeSection
                    wheelRow
                    deltaSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            if isExporting {
                exportOverlay
            }
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { exportComparisonPDF() } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundStyle(Theme.ink)
                .disabled(isExporting)
                .accessibilityLabel("Export comparison report")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $syncRotation) {
                    Image(systemName: syncRotation ? "lock.fill" : "lock.open")
                }
                .toggleStyle(.button)
                .foregroundStyle(Theme.ink)
                .accessibilityLabel("Sync mesh rotation")
            }
        }
        .sheet(item: $pdfShareItem, onDismiss: {
            // Delete the transient export whether the share sheet completed or
            // the practitioner swiped it away.
            cleanupItem?.cleanup()
            cleanupItem = nil
        }) { item in
            ShareSheet(items: [item.url]) {
                pdfShareItem = nil
            }
        }
        .alert("Export failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "The comparison report could not be generated.")
        }
        .task {
            let deltas = RegionProjectionChange.compute(
                from: visitA.capturedFace, to: visitB.capturedFace
            )
            regionChange = deltas.map { .computed($0) } ?? .incompatible
        }
    }

    // MARK: - Calibration banner

    /// Region tracking depends on calibrated landmark indices; warn when incomplete.
    /// TODO: Theme.warning token — amber mirrors the PDF calibration strip
    /// (0xB45309 ink on 0xFEF3C7).
    private var calibrationBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xB45309))
            Text("Landmark calibration incomplete — region tracking uses default vertex indices. Calibrate landmarks from a saved case for reliable comparisons.")
                .font(Type.caption)
                .foregroundStyle(Color(hex: 0xB45309))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(hex: 0xFEF3C7))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
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

    /// Shown on a side with no readable capture — the row never hides one-sided.
    private var placeholderMesh: some View {
        ZStack {
            Theme.surface
            Text("No capture recorded for this visit")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    // MARK: - Photo row (clinical before/after, shown when both visits have one)

    @ViewBuilder
    private var photoRow: some View {
        if let photoA = visitA.frontalPhotoJPEG.flatMap(UIImage.init(data:)),
           let photoB = visitB.frontalPhotoJPEG.flatMap(UIImage.init(data:)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CLINICAL PHOTOS").sectionHeaderStyle()
                HStack(spacing: 12) {
                    photoColumn(photoA)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.inkDim)
                    photoColumn(photoB)
                }
            }
        }
    }

    private func photoColumn(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
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

    // MARK: - Region projection change

    private var regionChangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REGION PROJECTION CHANGE").sectionHeaderStyle()
            switch regionChange {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Comparing captures…")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            case .incompatible:
                incompatibleCard
            case .computed(let deltas):
                regionChangeTable(deltas)
            }
        }
    }

    /// Explicit failure card — comparison must never silently hide.
    private var incompatibleCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkDim)
            VStack(alignment: .leading, spacing: 4) {
                Text("These two captures cannot be compared")
                    .font(Type.captionStrong)
                    .foregroundStyle(Theme.ink)
                Text("A mesh is missing for one visit, or the two meshes have mismatched topology. Region tracking needs two readable captures of the same mesh layout.")
                    .font(Type.caption)
                    .foregroundStyle(Theme.inkDim)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func regionChangeTable(_ deltas: [RegionProjectionDelta]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 4) {
                ForEach(deltas) { d in
                    HStack(alignment: .firstTextBaseline) {
                        Text(d.region.displayName)
                            .font(Type.caption)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(regionDeltaLabel(d))
                            .font(Type.caption.monospacedDigit())
                            .fontWeight(regionDeltaWeight(d))
                            .foregroundStyle(regionDeltaInk(d))
                    }
                }
            }
            Text("Mean regional Z-projection change. Changes within ±0.3 mm are at the capture noise floor and should not be over-read.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func regionDeltaLabel(_ d: RegionProjectionDelta) -> String {
        let mm = d.deltaMeters * 1000
        let value = String(format: "%@%.1f mm", mm < 0 ? "−" : "+", abs(mm))
        if d.isWithinNoiseFloor { return "\(value) · within noise" }
        return mm < 0 ? "\(value) · projection lost" : "\(value) · projection gained"
    }

    private func regionDeltaInk(_ d: RegionProjectionDelta) -> Color {
        if d.isWithinNoiseFloor { return Theme.inkMuted }
        return d.deltaMeters < 0 ? Self.worsenedInk : Self.improvedInk
    }

    private func regionDeltaWeight(_ d: RegionProjectionDelta) -> Font.Weight {
        // Lost projection (worsened) reads heavier than gained.
        (!d.isWithinNoiseFloor && d.deltaMeters < 0) ? .semibold : .regular
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
        let improved = d.severityB.ringIndex < d.severityA.ringIndex
        let worsened = d.severityB.ringIndex > d.severityA.ringIndex
        // Status colour only — facet hue stays on the DomainBadge for identity.
        let arrow: String
        let statusInk: Color
        switch (improved, worsened) {
        case (true, _):  arrow = "arrow.down.right"; statusInk = Self.improvedInk
        case (_, true):  arrow = "arrow.up.right";   statusInk = Self.worsenedInk
        default:         arrow = "arrow.right";      statusInk = Theme.inkMuted
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
                    Text(MetricValueFormatter.short(d.valueA, metricId: d.metricId))
                        .font(Type.caption.monospacedDigit())
                        .foregroundStyle(Theme.inkDim)
                    Image(systemName: arrow).font(.system(size: 11))
                        .foregroundStyle(statusInk)
                    Text(MetricValueFormatter.short(d.valueB, metricId: d.metricId))
                        .font(Type.caption.monospacedDigit())
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    // Worsened reads heavier (semibold brick) than improved (regular green).
                    Text(statusLabel(d, improved: improved, worsened: worsened))
                        .font(worsened ? Type.captionStrong : Type.caption)
                        .foregroundStyle(statusInk)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    private func statusLabel(_ d: Delta, improved: Bool, worsened: Bool) -> String {
        let a = d.severityA.rawValue.capitalized
        let b = d.severityB.rawValue.capitalized
        if worsened { return "Worsened · \(a) → \(b)" }
        if improved { return "Improved · \(a) → \(b)" }
        return a
    }

    // MARK: - Export

    private var exportOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            ProgressView("Preparing report…")
                .font(Type.caption)
                .tint(Theme.ink)
                .foregroundStyle(Theme.ink)
                .padding(20)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        }
    }

    private func exportComparisonPDF() {
        guard !isExporting else { return }
        isExporting = true
        Task { @MainActor in
            defer { isExporting = false }
            await Task.yield()   // let the progress overlay paint first

            let snapA = renderMeshSnapshot(for: visitA, results: resultsA)
            let snapB = renderMeshSnapshot(for: visitB, results: resultsB)
            guard let data = ComparisonReportPDF.generate(
                patient: patient,
                visitA: visitA,
                visitB: visitB,
                snapshotA: snapA,
                snapshotB: snapB
            ) else {
                exportErrorMessage = "The comparison report could not be rendered."
                showingExportError = true
                return
            }

            let stampA = ISO8601DateFormatter().string(from: visitA.createdAt).prefix(10)
            let stampB = ISO8601DateFormatter().string(from: visitB.createdAt).prefix(10)
            let name = "FaceMap_\(patient.code)_Compare_\(stampA)_to_\(stampB)"
            do {
                let item = try PDFShareItem.create(data, suggestedName: name)
                cleanupItem = item
                pdfShareItem = item
            } catch {
                exportErrorMessage = error.localizedDescription
                showingExportError = true
            }
        }
    }

    @MainActor
    private func renderMeshSnapshot(for visit: PatientCase,
                                    results: [MetricResult]) -> UIImage? {
        guard let face = visit.capturedFace else { return nil }
        let view = FaceMeshOverlay(
            face: face,
            regionSeverity: results.flaggedRegionsBySeverity,
            regionDomain: results.regionDomainsByWorstSeverity,
            controller: FaceMeshController()
        )
        .frame(width: 600, height: 400)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }
}
