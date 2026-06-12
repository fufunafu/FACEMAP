import SwiftUI

/// Type scale for FaceMap. New York (system serif) for displays and metric
/// names; SF Pro for UI; SF Mono for measurement values.
enum Type {

    // MARK: Display (New York serif)

    static let displayLarge = Font.system(size: 34, weight: .regular, design: .serif)
    static let displayMedium = Font.system(size: 24, weight: .regular, design: .serif)
    static let titleLarge   = Font.system(size: 20, weight: .medium,  design: .serif)
    static let metricName   = Font.system(size: 17, weight: .regular, design: .serif)

    // MARK: UI (SF Pro)

    static let body         = Font.system(size: 17, weight: .regular)
    static let callout      = Font.system(size: 15, weight: .regular)
    static let caption      = Font.system(size: 12, weight: .regular)
    static let captionStrong = Font.system(size: 12, weight: .semibold)

    // MARK: Numerals (monospaced)

    static let measurement      = Font.system(size: 15, weight: .regular).monospacedDigit()
    static let measurementLarge = Font.system(size: 28, weight: .regular).monospacedDigit()

    // MARK: Small caps section header (tracked SF)

    static let sectionHeader = Font.system(size: 11, weight: .semibold)

    // MARK: Micro labels & controls

    /// Smallest tracked label — wheel sector names, tiny captions.
    /// Apply `.tracking(1.0)` at the call site where letterspacing is wanted.
    static let micro      = Font.system(size: 9,  weight: .semibold)
    /// Small chip/badge label (domain badges, icon glyphs).
    static let labelSmall = Font.system(size: 10, weight: .semibold)
    /// Primary/ghost button label.
    static let button     = Font.system(size: 16, weight: .medium)
    /// Compact control text — toolbar glyphs, viewer-control buttons.
    static let control    = Font.system(size: 14, weight: .semibold)
}

// MARK: - View helpers

extension Text {
    /// Small-caps section header treatment.
    func sectionHeaderStyle() -> some View {
        self
            .font(Type.sectionHeader)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Theme.inkDim)
    }
}
