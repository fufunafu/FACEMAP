import SwiftUI

/// Print-safe colour mapping. The dark canvas reads poorly on paper, so PDF exports use a
/// neutral light background with the same domain hues for semantic consistency.
enum PDFTheme {
    static let pageBackground = Color.white
    static let pageInk        = Color.black
    static let pageInkDim     = Color(white: 0.35)
    static let pageInkMuted   = Color(white: 0.55)
    static let pageHairline   = Color(white: 0.85)
    static let pageSurface    = Color(white: 0.97)

    /// Calibration-warning amber, matching the in-app banner treatment.
    /// TODO: Theme.warning token — promote to the app-wide Theme when one lands.
    static let warningInk        = Color(hex: 0xB45309)
    static let warningBackground = Color(hex: 0xFEF3C7)

    /// Status colours for visit-over-visit change. Desaturated so they read as
    /// annotations, not alarms. Never use facet/domain hues for status meaning.
    /// TODO: Theme.statusWorsened / Theme.statusImproved tokens.
    static let statusWorsened = Color(hex: 0x9B3B2E)   // desaturated brick
    static let statusImproved = Color(hex: 0x3E7C4F)   // desaturated green

    static let pageWidth:  CGFloat = 595   // A4 portrait, 72dpi
    static let pageHeight: CGFloat = 842

    static let margin:    CGFloat = 36
    static let gutter:    CGFloat = 18
}

// MARK: - PDF type scale

/// Type scale for PDF export. Mirrors the on-screen `Type` scale at print sizes:
/// New York (system serif) for displays and metric names; SF for UI; mono digits
/// for measurement values. Legal/disclaimer copy must never render below 8.5pt.
enum PDFType {
    /// 24pt serif display — pair with `.tracking(PDFType.displayTracking)`.
    static let display       = Font.system(size: 24, weight: .regular, design: .serif)
    static let displayTracking: CGFloat = 3

    /// 9pt semibold section header — pair with `.tracking(PDFType.sectionHeaderTracking)`.
    static let sectionHeader = Font.system(size: 9, weight: .semibold)
    static let sectionHeaderTracking: CGFloat = 1.2

    static let body          = Font.system(size: 10, weight: .regular)
    static let bodyStrong    = Font.system(size: 10, weight: .semibold)
    static let metricName    = Font.system(size: 10.5, weight: .regular, design: .serif)
    static let value         = Font.system(size: 10, weight: .regular).monospacedDigit()
    static let caption       = Font.system(size: 9, weight: .regular)

    /// Minimum size for disclaimer / legal copy. Do not shrink below this.
    static let legalPointSize: CGFloat = 8.5
    static let legal         = Font.system(size: legalPointSize, weight: .regular)
}

// MARK: - Shared metric value formatting

/// Single source of truth for rendering a metric value with correct units, keyed by
/// metric id. Mirrors `AnalysisScreen.formatValue` so the analysis screen, the
/// comparison screen, and both PDF reports always agree:
/// - canthal tilt — degrees
/// - asymmetry & surface displacement — millimetres (stored in metres)
/// - thirds / fifths / golden ratio — percent deviation (stored as fraction)
/// - expression-asymmetry and skin-quality texture indices — unitless, NEVER ×100
enum MetricValueFormatter {

    /// Short form: just the value with its unit ("2.4 mm", "6.1°", "12.5%", "0.84").
    static func short(_ value: Double, metricId: String) -> String {
        if value.isNaN { return "—" }
        switch metricId {
        case CanthalTiltMetric.id:
            return String(format: "%.1f°", value)
        case AsymmetryMetric.id, SurfaceDisplacementMetric.id:
            return String(format: "%.1f mm", value * 1000)
        case FacialThirdsMetric.id, FacialFifthsMetric.id, GoldenRatioMetric.id:
            return String(format: "%.1f%%", value * 100)
        default:
            // Unitless metrics (expression-asymmetry ratio, skin-quality texture
            // index, and any future metric without a registered unit). Mirrors the
            // AnalysisScreen default — never multiply an unknown unit by 100.
            return String(format: "%.2f", value)
        }
    }

    /// Long form with the target range, for detail rows and PDF tables.
    static func withTarget(_ r: MetricResult) -> String {
        if r.value.isNaN { return r.notes ?? "Unavailable" }
        switch r.metricId {
        case CanthalTiltMetric.id:
            return String(format: "%.1f° (target %.0f–%.0f°)",
                          r.value, r.target.lowerBound, r.target.upperBound)
        case AsymmetryMetric.id:
            return String(format: "%.1f mm worst pair (target ≤ %.1f mm)",
                          r.value * 1000, r.target.upperBound * 1000)
        case SurfaceDisplacementMetric.id:
            return String(format: "%.1f mm worst Z-deficit (target ≤ %.1f mm)",
                          r.value * 1000, r.target.upperBound * 1000)
        case FacialThirdsMetric.id, FacialFifthsMetric.id, GoldenRatioMetric.id:
            return String(format: "%.1f%% deviation (target ≤ %.0f%%)",
                          r.value * 100, r.target.upperBound * 100)
        default:
            return String(format: "%.2f (target %.2f–%.2f)",
                          r.value, r.target.lowerBound, r.target.upperBound)
        }
    }

    /// Signed delta in the metric's own unit ("+1.2 mm", "−0.4°"). Used in
    /// comparison tables; sign always shown so direction is unambiguous.
    static func signedDelta(_ delta: Double, metricId: String) -> String {
        if delta.isNaN { return "—" }
        let sign = delta < 0 ? "−" : "+"
        let magnitude = abs(delta)
        switch metricId {
        case CanthalTiltMetric.id:
            return String(format: "%@%.1f°", sign, magnitude)
        case AsymmetryMetric.id, SurfaceDisplacementMetric.id:
            return String(format: "%@%.1f mm", sign, magnitude * 1000)
        case FacialThirdsMetric.id, FacialFifthsMetric.id, GoldenRatioMetric.id:
            return String(format: "%@%.1f%%", sign, magnitude * 100)
        default:
            return String(format: "%@%.2f", sign, magnitude)
        }
    }
}
