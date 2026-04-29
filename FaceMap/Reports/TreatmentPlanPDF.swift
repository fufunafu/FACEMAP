import SwiftUI
import PDFKit
import UIKit

/// Renders a single-page A4 treatment-planning sheet for one `PatientCase`.
/// Dr Nikolis's name is in the header; the disclaimer is in the footer.
/// Patient data: pseudonymous code only — no PII.
@MainActor
enum TreatmentPlanPDF {

    /// Compose a PDF document for a case. Caller passes a snapshot of the mesh image.
    /// Returns the PDF data, or nil if rendering failed.
    static func generate(patient: Patient,
                         visit: PatientCase,
                         meshSnapshot: UIImage?) -> Data? {
        let renderer = ImageRenderer(content: PDFPageView(
            patient: patient,
            visit: visit,
            results: visit.metricResults,
            pins: visit.annotations,
            meshSnapshot: meshSnapshot
        ).frame(width: PDFTheme.pageWidth, height: PDFTheme.pageHeight))

        renderer.proposedSize = ProposedViewSize(
            width: PDFTheme.pageWidth, height: PDFTheme.pageHeight
        )

        let data = NSMutableData()
        renderer.render { size, drawingContext in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: data),
                  let context = CGContext(consumer: consumer, mediaBox: &box, nil)
            else { return }
            context.beginPDFPage(nil)
            drawingContext(context)
            context.endPDFPage()
            context.closePDF()
        }
        return data as Data
    }
}

// MARK: - Page layout

struct PDFPageView: View {
    let patient: Patient
    let visit: PatientCase
    let results: [MetricResult]
    let pins: [AnnotationPin]
    let meshSnapshot: UIImage?

    var body: some View {
        ZStack {
            PDFTheme.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                    .padding(.top, PDFTheme.margin)
                    .padding(.horizontal, PDFTheme.margin)

                Rectangle().fill(PDFTheme.pageHairline).frame(height: 1)
                    .padding(.top, 14).padding(.horizontal, PDFTheme.margin)

                HStack(alignment: .top, spacing: PDFTheme.gutter) {
                    leftColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                    rightColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PDFTheme.margin)
                .padding(.top, 16)

                Spacer()

                signatureBlock
                    .padding(.horizontal, PDFTheme.margin)

                footer
                    .padding(.horizontal, PDFTheme.margin)
                    .padding(.top, 8)
                    .padding(.bottom, PDFTheme.margin)
            }
        }
        .frame(width: PDFTheme.pageWidth, height: PDFTheme.pageHeight)
    }

    // MARK: Header (BrandMark + patient + date)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FACEMAP")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .tracking(4)
                    .foregroundStyle(PDFTheme.pageInk)
                Text("Prepared by Dr Andreas Nikolis · MD, FRCSC")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Patient: \(patient.code)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PDFTheme.pageInk)
                Text("Visit: \(visit.label)")
                    .font(.system(size: 10))
                    .foregroundStyle(PDFTheme.pageInkDim)
                Text(visit.createdAt.formatted(date: .long, time: .shortened))
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
        }
    }

    // MARK: Left column — mesh image + wheel

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("MESH SNAPSHOT")
            ZStack {
                Color.black
                if let img = meshSnapshot {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Mesh image unavailable")
                        .foregroundStyle(.white)
                        .font(.system(size: 10))
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            sectionHeader("AESTHETIC WHEEL")
            AestheticWheel(results: results, diameter: 200, showsLabels: true)
                .frame(height: 220)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Right column — metric table + pins + notes

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("METRICS")
            VStack(spacing: 4) {
                ForEach(results, id: \.metricId) { r in
                    metricRow(r)
                }
            }

            if !pins.isEmpty {
                sectionHeader("ANNOTATION PINS")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(pins) { pin in pinRow(pin) }
                }
            }

            if !visit.notes.isEmpty {
                sectionHeader("NOTES")
                Text(visit.notes)
                    .font(.system(size: 10))
                    .foregroundStyle(PDFTheme.pageInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(PDFTheme.pageSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
    }

    private func metricRow(_ r: MetricResult) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(r.severity == .normal
                      ? PDFTheme.pageInkMuted
                      : r.domain.hue)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(r.metricName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(PDFTheme.pageInk)
                    Spacer()
                    Text(r.severity.rawValue.capitalized)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(r.severity == .normal
                                         ? PDFTheme.pageInkDim
                                         : PDFTheme.pageInk)
                }
                Text(formatPDFValue(r))
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
        }
        .padding(6)
        .background(PDFTheme.pageSurface)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func pinRow(_ pin: AnnotationPin) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
                .fill(pin.domain?.hue ?? PDFTheme.pageInk)
                .frame(width: 6, height: 6)
            Text(pin.label)
                .font(.system(size: 10))
                .foregroundStyle(PDFTheme.pageInk)
            Spacer()
            if let s = pin.severity {
                Text(s.rawValue.capitalized)
                    .font(.system(size: 9))
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
        }
    }

    // MARK: Signature + footer

    private var signatureBlock: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(PDFTheme.pageInk).frame(height: 0.5)
                Text("Practitioner signature — Dr Andreas Nikolis, MD, FRCSC")
                    .font(.system(size: 9))
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(PDFTheme.pageInk).frame(height: 0.5)
                Text("Date")
                    .font(.system(size: 9))
                    .foregroundStyle(PDFTheme.pageInkDim)
            }
            .frame(maxWidth: 140)
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Rectangle().fill(PDFTheme.pageHairline).frame(height: 1)
            HStack {
                Text(DisclaimerCopy.pdfFooter)
                    .font(.system(size: 8))
                    .foregroundStyle(PDFTheme.pageInkMuted)
                Spacer()
                Text("FaceMap v0.2 · Page 1 of 1")
                    .font(.system(size: 8).monospacedDigit())
                    .foregroundStyle(PDFTheme.pageInkMuted)
            }
            .padding(.top, 4)
        }
    }

    // MARK: Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(PDFTheme.pageInkDim)
    }

    private func formatPDFValue(_ r: MetricResult) -> String {
        if r.value.isNaN { return "—" }
        switch r.metricId {
        case CanthalTiltMetric.id: return String(format: "%.1f° (target %.0f–%.0f°)",
                                                 r.value, r.target.lowerBound, r.target.upperBound)
        case AsymmetryMetric.id:   return String(format: "%.1f mm worst (≤ %.1f mm)",
                                                 r.value * 1000, r.target.upperBound * 1000)
        default:                   return String(format: "%.1f%% (≤ %.0f%%)",
                                                 r.value * 100, r.target.upperBound * 100)
        }
    }
}
