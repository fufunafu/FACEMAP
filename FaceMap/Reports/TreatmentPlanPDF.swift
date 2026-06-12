import SwiftUI
import PDFKit
import UIKit

// MARK: - Practitioner attribution

/// Who the report says prepared it. Read from the Settings field stored under the
/// UserDefaults key `"practitionerName"`. When unset, reports say "Prepared with
/// FaceMap" and the signature line is left blank — never default to a named clinician.
enum PDFAttribution {
    static let practitionerNameKey = "practitionerName"

    static var practitionerName: String? {
        let raw = UserDefaults.standard.string(forKey: practitionerNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }

    static var preparedByLine: String {
        if let name = practitionerName { return "Prepared by \(name)" }
        return "Prepared with FaceMap"
    }
}

// MARK: - Region projection change (visit-over-visit)

/// Mean Z-projection change of one facial region between two captures of the
/// same patient, in metres. Positive = the region projects further out of the
/// face at the newer visit.
struct RegionProjectionDelta: Identifiable {
    let region: FacialRegion
    let deltaMeters: Double
    var id: String { region.rawValue }

    /// Below this magnitude the change is within ARKit capture noise.
    static let noiseFloorMeters: Double = 0.0003   // ±0.3 mm

    var isWithinNoiseFloor: Bool { abs(deltaMeters) <= Self.noiseFloorMeters }
}

/// Computes per-region mean-Z projection change between two captures. ARKit's face
/// mesh has fixed topology, so vertex N is the same anatomical point in both meshes;
/// a vertex-count mismatch means the captures cannot be compared.
///
/// NOTE: when a dedicated `SurfaceChangeAnalyzer` lands, this helper should delegate
/// to it — the contract here (nil = incompatible, [] never returned) must be kept.
enum RegionProjectionChange {

    /// Returns one delta per region with known vertices, ordered as `FacialRegion.allCases`.
    /// Returns nil when either mesh is missing or the topologies don't match.
    static func compute(from older: CapturedFace?, to newer: CapturedFace?) -> [RegionProjectionDelta]? {
        guard let a = older, let b = newer else { return nil }
        let va = a.vertices
        let vb = b.vertices
        guard !va.isEmpty, va.count == vb.count else { return nil }

        var out: [RegionProjectionDelta] = []
        for region in FacialRegion.allCases {
            guard let indices = FaceLandmarkIndices.regionVertices[region],
                  !indices.isEmpty else { continue }
            var sumA: Float = 0, sumB: Float = 0
            var count = 0
            for i in indices where i >= 0 && i < va.count {
                sumA += va[i].z
                sumB += vb[i].z
                count += 1
            }
            guard count > 0 else { continue }
            let delta = Double((sumB - sumA) / Float(count))
            out.append(RegionProjectionDelta(region: region, deltaMeters: delta))
        }
        return out.isEmpty ? nil : out
    }
}

// MARK: - Multi-page render engine

/// Renders a list of fixed-size A4 SwiftUI pages into a single PDF document.
@MainActor
enum PDFRenderEngine {
    static func render(pages: [AnyView]) -> Data? {
        guard !pages.isEmpty else { return nil }
        let data = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: PDFTheme.pageWidth, height: PDFTheme.pageHeight)
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil)
        else { return nil }

        for page in pages {
            let renderer = ImageRenderer(content: page
                .frame(width: PDFTheme.pageWidth, height: PDFTheme.pageHeight))
            renderer.proposedSize = ProposedViewSize(
                width: PDFTheme.pageWidth, height: PDFTheme.pageHeight
            )
            renderer.render { _, drawingContext in
                context.beginPDFPage(nil)
                drawingContext(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        return data.length > 0 ? (data as Data) : nil
    }
}

// MARK: - Treatment plan (multi-page)

/// Renders the A4 treatment-planning report for one `PatientCase`.
/// Page 1 is patient-facing (photos, wheel, key findings, signature); page 2 is
/// clinical detail (facet-grouped metrics, change since last visit, pins); notes
/// paginate onto page 3+. The not-a-medical-device disclaimer footer is on every page.
/// Patient data: pseudonymous code only — no PII.
@MainActor
enum TreatmentPlanPDF {

    /// Compose a PDF document for a case. Caller passes a snapshot of the mesh image.
    /// Returns the PDF data, or nil if rendering failed.
    static func generate(patient: Patient,
                         visit: PatientCase,
                         meshSnapshot: UIImage?) -> Data? {
        let results = visit.metricResults
        let pins = visit.annotations

        // Most recent visit for the same patient that predates this one.
        let priorVisit = patient.sortedCases.first {
            $0.id != visit.id && $0.createdAt < visit.createdAt
        }
        let regionDeltas: [RegionProjectionDelta]? = priorVisit.flatMap {
            RegionProjectionChange.compute(from: $0.capturedFace, to: visit.capturedFace)
        }

        var bodies: [AnyView] = []
        bodies.append(AnyView(TreatmentPlanPageOne(
            patient: patient,
            visit: visit,
            results: results,
            meshSnapshot: meshSnapshot
        )))
        bodies.append(AnyView(TreatmentPlanPageTwo(
            patient: patient,
            visit: visit,
            results: results,
            pins: pins,
            priorVisit: priorVisit,
            regionDeltas: regionDeltas
        )))

        if let notes = visit.notes,
           !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            for chunk in PDFNotesPaginator.chunks(notes) {
                bodies.append(AnyView(PDFNotesPage(patient: patient, visit: visit, text: chunk)))
            }
        }

        let total = bodies.count
        let pages = bodies.enumerated().map { index, body in
            AnyView(PDFPageShell(pageNumber: index + 1, pageCount: total) { body })
        }
        return PDFRenderEngine.render(pages: pages)
    }
}

// MARK: - Comparison report (before / after)

/// One-page before/after report for two visits of the same patient: side-by-side
/// frontal captures, the region projection-change table, and the metric A→B delta
/// table. The disclaimer footer is on every page.
@MainActor
enum ComparisonReportPDF {

    static func generate(patient: Patient,
                         visitA: PatientCase,
                         visitB: PatientCase,
                         snapshotA: UIImage?,
                         snapshotB: UIImage?) -> Data? {
        let regionDeltas = RegionProjectionChange.compute(
            from: visitA.capturedFace, to: visitB.capturedFace
        )
        let body = AnyView(ComparisonReportPage(
            patient: patient,
            visitA: visitA,
            visitB: visitB,
            snapshotA: snapshotA,
            snapshotB: snapshotB,
            regionDeltas: regionDeltas
        ))
        let page = AnyView(PDFPageShell(pageNumber: 1, pageCount: 1) { body })
        return PDFRenderEngine.render(pages: [page])
    }
}

// MARK: - Notes pagination

enum PDFNotesPaginator {
    /// Conservative characters-per-page budget for 10pt body text inside the
    /// content area of an A4 page — guarantees a chunk never clips.
    static let charactersPerPage = 2600

    /// Splits long notes into page-sized chunks at word boundaries.
    static func chunks(_ text: String, limit: Int = charactersPerPage) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed.isEmpty ? [] : [trimmed] }

        var remaining = Substring(trimmed)
        var out: [String] = []
        while !remaining.isEmpty {
            if remaining.count <= limit {
                out.append(String(remaining))
                break
            }
            let hardEnd = remaining.index(remaining.startIndex, offsetBy: limit)
            let window = remaining[..<hardEnd]
            // Prefer breaking at the last newline, then the last space.
            let breakIndex = window.lastIndex(of: "\n")
                ?? window.lastIndex(of: " ")
                ?? hardEnd
            let cut = breakIndex == remaining.startIndex ? hardEnd : breakIndex
            out.append(String(remaining[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines))
            remaining = remaining[cut...].drop(while: { $0 == " " || $0 == "\n" })
        }
        return out
    }
}

// MARK: - Page shell (chrome shared by every page)

/// Fixed-size A4 page wrapper: white background, content area, then the calibration
/// strip and disclaimer footer pinned to the bottom of EVERY page.
struct PDFPageShell<Content: View>: View {
    let pageNumber: Int
    let pageCount: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            PDFTheme.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                PDFCalibrationStrip()
                    .padding(.horizontal, PDFTheme.margin)
                    .padding(.top, 8)
                PDFDisclaimerFooter(pageNumber: pageNumber, pageCount: pageCount)
                    .padding(.horizontal, PDFTheme.margin)
                    .padding(.top, 6)
                    .padding(.bottom, PDFTheme.margin)
            }
        }
        .frame(width: PDFTheme.pageWidth, height: PDFTheme.pageHeight)
    }
}

/// Landmark-calibration status strip. Amber when calibration is incomplete because
/// region tracking and landmark metrics then rely on default vertex indices.
/// TODO: Theme.warning token — colors mirror the in-app banner (0xB45309 on 0xFEF3C7).
struct PDFCalibrationStrip: View {
    private let calibrated = LandmarkCalibrationStore.shared.calibratedCount
    private let total = AnatomicalLandmark.allCases.count

    var body: some View {
        if calibrated < total {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(PDFTheme.warningInk)
                Text("Landmark calibration incomplete (\(calibrated)/\(total)) — measurements use default vertex indices.")
                    .font(PDFType.legal)
                    .foregroundStyle(PDFTheme.warningInk)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PDFTheme.warningBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            HStack {
                Text("All \(total) landmarks practitioner-calibrated.")
                    .font(PDFType.legal)
                    .foregroundStyle(PDFTheme.pageInkMuted)
                Spacer()
            }
        }
    }
}

/// Not-a-medical-device disclaimer footer. Must appear on every page and must
/// never render below `PDFType.legalPointSize` (8.5pt).
struct PDFDisclaimerFooter: View {
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        VStack(spacing: 4) {
            Rectangle().fill(PDFTheme.pageHairline).frame(height: 1)
            HStack(alignment: .top) {
                Text(DisclaimerCopy.pdfFooter)
                    .font(PDFType.legal)
                    .foregroundStyle(PDFTheme.pageInkDim)
                Spacer()
                Text("FaceMap v0.5 · Page \(pageNumber) of \(pageCount)")
                    .font(PDFType.legal.monospacedDigit())
                    .foregroundStyle(PDFTheme.pageInkMuted)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Shared header

struct PDFReportHeader: View {
    let patient: Patient
    let visitLine: String
    let dateLine: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FACEMAP")
                        .font(PDFType.display)
                        .tracking(PDFType.displayTracking)
                        .foregroundStyle(PDFTheme.pageInk)
                    Text(PDFAttribution.preparedByLine)
                        .font(PDFType.bodyStrong)
                        .foregroundStyle(PDFTheme.pageInkDim)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Patient: \(patient.code)")
                        .font(PDFType.bodyStrong)
                        .foregroundStyle(PDFTheme.pageInk)
                    Text(visitLine)
                        .font(PDFType.body)
                        .foregroundStyle(PDFTheme.pageInkDim)
                    Text(dateLine)
                        .font(PDFType.value)
                        .foregroundStyle(PDFTheme.pageInkDim)
                }
            }
            Rectangle().fill(PDFTheme.pageHairline).frame(height: 1)
                .padding(.top, 12)
        }
    }
}

struct PDFSectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(PDFType.sectionHeader)
            .tracking(PDFType.sectionHeaderTracking)
            .foregroundStyle(PDFTheme.pageInkDim)
    }
}

// MARK: - Page 1 (patient-facing)

struct TreatmentPlanPageOne: View {
    let patient: Patient
    let visit: PatientCase
    let results: [MetricResult]
    let meshSnapshot: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PDFReportHeader(
                patient: patient,
                visitLine: "Visit: \(visit.label)",
                dateLine: visit.createdAt.formatted(date: .long, time: .shortened)
            )

            PDFSectionHeader("CLINICAL CAPTURES")
            PDFPhotoTriptych(slots: [
                .init(caption: "Oblique L", image: nil),
                .init(caption: "Frontal", image: meshSnapshot),
                .init(caption: "Oblique R", image: nil),
            ])

            HStack(alignment: .top, spacing: PDFTheme.gutter) {
                VStack(alignment: .leading, spacing: 8) {
                    PDFSectionHeader("AESTHETIC WHEEL")
                    // Bleed margin: wheel labels sit at radius × 1.02, so the frame
                    // is comfortably larger than the wheel diameter to avoid clipping.
                    AestheticWheel(results: results, diameter: 168, showsLabels: true)
                        .frame(width: 230, height: 220)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    PDFSectionHeader("KEY FINDINGS")
                    PDFKeyFindingsBox(results: results)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            PDFSignatureBlock()
        }
        .padding(.top, PDFTheme.margin)
        .padding(.horizontal, PDFTheme.margin)
    }
}

struct PDFPhotoTriptych: View {
    struct Slot {
        let caption: String
        let image: UIImage?
    }
    let slots: [Slot]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                VStack(alignment: .leading, spacing: 4) {
                    ZStack {
                        if let img = slot.image {
                            Color.black
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            PDFTheme.pageSurface
                            Text("No photo recorded\nfor this visit")
                                .font(PDFType.caption)
                                .foregroundStyle(PDFTheme.pageInkMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(slot.caption)
                        .font(PDFType.caption)
                        .foregroundStyle(PDFTheme.pageInkDim)
                }
            }
        }
    }
}

struct PDFKeyFindingsBox: View {
    let results: [MetricResult]

    private var topFindings: [MetricResult] {
        results
            .filter { $0.severity != .normal && !$0.value.isNaN }
            .sorted {
                if $0.severity.ringIndex != $1.severity.ringIndex {
                    return $0.severity.ringIndex > $1.severity.ringIndex
                }
                return abs($0.deviation) > abs($1.deviation)
            }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if topFindings.isEmpty {
                Text("All measured metrics are within their target ranges at this visit.")
                    .font(PDFType.body)
                    .foregroundStyle(PDFTheme.pageInk)
            } else {
                ForEach(topFindings, id: \.metricId) { r in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(r.metricName) — \(r.severity.rawValue.capitalized)")
                            .font(PDFType.bodyStrong)
                            .foregroundStyle(PDFTheme.pageInk)
                        Text(MetricValueFormatter.withTarget(r))
                            .font(PDFType.caption.monospacedDigit())
                            .foregroundStyle(PDFTheme.pageInkDim)
                    }
                }
            }
            Text("Computational outputs from geometric measurement — not clinical recommendations.")
                .font(PDFType.legal)
                .foregroundStyle(PDFTheme.pageInkMuted)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PDFTheme.pageSurface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(PDFTheme.pageHairline, lineWidth: 1)
        )
    }
}

/// Signature block. Names the practitioner only when one is configured in Settings;
/// otherwise leaves a blank line — never attributes the report to a default clinician.
struct PDFSignatureBlock: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(PDFTheme.pageInk).frame(height: 0.5)
                Text(signatureCaption)
                    .font(PDFType.caption)
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(PDFTheme.pageInk).frame(height: 0.5)
                Text("Date")
                    .font(PDFType.caption)
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            .frame(maxWidth: 140)
        }
    }

    private var signatureCaption: String {
        if let name = PDFAttribution.practitionerName {
            return "Practitioner signature — \(name)"
        }
        return "Practitioner signature"
    }
}

// MARK: - Page 2 (clinical detail)

struct TreatmentPlanPageTwo: View {
    let patient: Patient
    let visit: PatientCase
    let results: [MetricResult]
    let pins: [AnnotationPin]
    let priorVisit: PatientCase?
    let regionDeltas: [RegionProjectionDelta]?

    private var populatedFacets: [FaceDomain] {
        FaceDomain.allCases.filter { d in results.contains { $0.domain == d } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PDFReportHeader(
                patient: patient,
                visitLine: "Visit: \(visit.label) · Clinical detail",
                dateLine: visit.createdAt.formatted(date: .long, time: .shortened)
            )

            PDFSectionHeader("METRICS BY FACET")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(populatedFacets) { facet in
                    facetGroup(facet)
                }
            }

            if let prior = priorVisit {
                PDFSectionHeader("CHANGE SINCE LAST VISIT")
                PDFRegionChangeTable(
                    deltas: regionDeltas,
                    contextLine: "vs \(prior.label) · \(prior.createdAt.formatted(date: .abbreviated, time: .omitted))"
                )
            }

            if !pins.isEmpty {
                PDFSectionHeader("ANNOTATION PINS")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(pins) { pin in pinRow(pin) }
                }
            }
        }
        .padding(.top, PDFTheme.margin)
        .padding(.horizontal, PDFTheme.margin)
    }

    /// One facet group: a facet-hue identity tab beside the group's metric rows.
    /// Hue marks facet identity only — severity is carried by the text labels.
    private func facetGroup(_ facet: FaceDomain) -> some View {
        let rows = results.filter { $0.domain == facet }
        return HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(facet.hue)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 4) {
                Text(facet.displayName.uppercased())
                    .font(PDFType.sectionHeader)
                    .tracking(PDFType.sectionHeaderTracking)
                    .foregroundStyle(PDFTheme.pageInkDim)
                ForEach(rows, id: \.metricId) { r in
                    metricRow(r)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func metricRow(_ r: MetricResult) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(r.metricName)
                .font(PDFType.metricName)
                .foregroundStyle(PDFTheme.pageInk)
            Spacer()
            Text(MetricValueFormatter.withTarget(r))
                .font(PDFType.value)
                .foregroundStyle(PDFTheme.pageInkDim)
            Text(r.severity.rawValue.capitalized)
                .font(r.severity == .normal ? PDFType.caption : PDFType.bodyStrong)
                .foregroundStyle(r.severity == .normal ? PDFTheme.pageInkDim : PDFTheme.pageInk)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(PDFTheme.pageSurface)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func pinRow(_ pin: AnnotationPin) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
                .fill(pin.domain?.hue ?? PDFTheme.pageInk)
                .frame(width: 6, height: 6)
            Text(pin.label)
                .font(PDFType.body)
                .foregroundStyle(PDFTheme.pageInk)
            Spacer()
            if let s = pin.severity {
                Text(s.rawValue.capitalized)
                    .font(PDFType.caption)
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
        }
    }
}

/// Region projection-change table (two columns) with the noise-floor note.
/// When `deltas` is nil the captures are incompatible and this renders an
/// explicit explanation instead of silently hiding.
struct PDFRegionChangeTable: View {
    let deltas: [RegionProjectionDelta]?
    var contextLine: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let contextLine {
                Text(contextLine)
                    .font(PDFType.caption)
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            if let deltas {
                let midpoint = (deltas.count + 1) / 2
                HStack(alignment: .top, spacing: PDFTheme.gutter) {
                    column(Array(deltas.prefix(midpoint)))
                    column(Array(deltas.dropFirst(midpoint)))
                }
                Text("Mean regional Z-projection change. Changes within ±0.3 mm are at the capture noise floor and should not be over-read.")
                    .font(PDFType.legal)
                    .foregroundStyle(PDFTheme.pageInkMuted)
            } else {
                Text("These two captures cannot be compared (mesh missing or topology mismatch).")
                    .font(PDFType.body)
                    .foregroundStyle(PDFTheme.pageInkDim)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PDFTheme.pageSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
    }

    private func column(_ rows: [RegionProjectionDelta]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(rows) { d in
                HStack(alignment: .firstTextBaseline) {
                    Text(d.region.displayName)
                        .font(PDFType.caption)
                        .foregroundStyle(PDFTheme.pageInk)
                    Spacer()
                    Text(deltaLabel(d))
                        .font(PDFType.value)
                        .foregroundStyle(deltaInk(d))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func deltaLabel(_ d: RegionProjectionDelta) -> String {
        let mm = d.deltaMeters * 1000
        return String(format: "%@%.1f mm", mm < 0 ? "−" : "+", abs(mm))
    }

    private func deltaInk(_ d: RegionProjectionDelta) -> Color {
        if d.isWithinNoiseFloor { return PDFTheme.pageInkMuted }
        // Projection lost (more recessed) is the change a practitioner watches for.
        return d.deltaMeters < 0 ? PDFTheme.statusWorsened : PDFTheme.statusImproved
    }
}

// MARK: - Notes pages (page 3+)

struct PDFNotesPage: View {
    let patient: Patient
    let visit: PatientCase
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PDFReportHeader(
                patient: patient,
                visitLine: "Visit: \(visit.label) · Notes",
                dateLine: visit.createdAt.formatted(date: .long, time: .shortened)
            )
            PDFSectionHeader("CLINICIAN NOTES")
            Text(text)
                .font(PDFType.body)
                .foregroundStyle(PDFTheme.pageInk)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(8)
                .background(PDFTheme.pageSurface)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .padding(.top, PDFTheme.margin)
        .padding(.horizontal, PDFTheme.margin)
    }
}

// MARK: - Comparison report page

struct ComparisonReportPage: View {
    let patient: Patient
    let visitA: PatientCase
    let visitB: PatientCase
    let snapshotA: UIImage?
    let snapshotB: UIImage?
    let regionDeltas: [RegionProjectionDelta]?

    private var dayCount: Int {
        Calendar.current.dateComponents(
            [.day], from: visitA.createdAt, to: visitB.createdAt
        ).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PDFReportHeader(
                patient: patient,
                visitLine: "Comparison: \(visitA.label) → \(visitB.label)",
                dateLine: "\(dayCount) day\(dayCount == 1 ? "" : "s") between visits"
            )

            PDFSectionHeader("FRONTAL CAPTURES")
            HStack(alignment: .top, spacing: 10) {
                captureSlot(label: "Visit A · \(visitA.createdAt.formatted(date: .abbreviated, time: .omitted))",
                            image: snapshotA)
                captureSlot(label: "Visit B · \(visitB.createdAt.formatted(date: .abbreviated, time: .omitted))",
                            image: snapshotB)
            }

            PDFSectionHeader("REGION PROJECTION CHANGE")
            PDFRegionChangeTable(deltas: regionDeltas)

            PDFSectionHeader("METRIC CHANGES")
            VStack(alignment: .leading, spacing: 3) {
                ForEach(metricDeltas, id: \.metricId) { d in
                    metricDeltaRow(d)
                }
            }
        }
        .padding(.top, PDFTheme.margin)
        .padding(.horizontal, PDFTheme.margin)
    }

    private func captureSlot(label: String, image: UIImage?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                if let image {
                    Color.black
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    PDFTheme.pageSurface
                    Text("No capture recorded\nfor this visit")
                        .font(PDFType.caption)
                        .foregroundStyle(PDFTheme.pageInkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(label)
                .font(PDFType.caption)
                .foregroundStyle(PDFTheme.pageInkDim)
        }
    }

    private struct MetricDelta {
        let metricId: String
        let metricName: String
        let valueA: Double
        let valueB: Double
        let severityA: MetricResult.Severity
        let severityB: MetricResult.Severity
    }

    private var metricDeltas: [MetricDelta] {
        let mapA = Dictionary(uniqueKeysWithValues: visitA.metricResults.map { ($0.metricId, $0) })
        let mapB = Dictionary(uniqueKeysWithValues: visitB.metricResults.map { ($0.metricId, $0) })
        return Set(mapA.keys).union(mapB.keys).sorted().map { id in
            MetricDelta(
                metricId: id,
                metricName: mapA[id]?.metricName ?? mapB[id]?.metricName ?? id,
                valueA: mapA[id]?.value ?? .nan,
                valueB: mapB[id]?.value ?? .nan,
                severityA: mapA[id]?.severity ?? .normal,
                severityB: mapB[id]?.severity ?? .normal
            )
        }
    }

    private func metricDeltaRow(_ d: MetricDelta) -> some View {
        let worsened = d.severityB.ringIndex > d.severityA.ringIndex
        let improved = d.severityB.ringIndex < d.severityA.ringIndex
        let statusText = worsened ? "Worsened" : (improved ? "Improved" : "Unchanged")
        let statusInk: Color = worsened
            ? PDFTheme.statusWorsened
            : (improved ? PDFTheme.statusImproved : PDFTheme.pageInkMuted)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(d.metricName)
                .font(PDFType.metricName)
                .foregroundStyle(PDFTheme.pageInk)
            Spacer()
            Text("\(MetricValueFormatter.short(d.valueA, metricId: d.metricId)) → \(MetricValueFormatter.short(d.valueB, metricId: d.metricId))")
                .font(PDFType.value)
                .foregroundStyle(PDFTheme.pageInkDim)
            Text(statusText)
                .font(worsened ? PDFType.bodyStrong : PDFType.caption)
                .foregroundStyle(statusInk)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(PDFTheme.pageSurface)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
