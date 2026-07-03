import SwiftUI

/// Visual tokens for FaceMap, aligned to Dr Andreas Nikolis's five-facet
/// Facial Assessment Scale (FAS). Light surfaces, near-black ink, five facet hues.
/// Severity is expressed as ring intensity within a facet hue (1/2/3),
/// not as a separate red/amber/green ramp.
///
/// Note: the 3D mesh viewport keeps a black interior so the rendered face pops —
/// a deliberate "spotlight" against the otherwise light chrome.
enum Theme {

    // MARK: Surfaces

    static let canvas         = Color(hex: 0xFAFAFA)   // off-white page
    static let surface        = Color(hex: 0xFFFFFF)   // cards, list rows
    static let surfaceRaised  = Color(hex: 0xF1F1F4)   // sheets, modals, raised
    static let hairline       = Color.black.opacity(0.10)

    /// Black background reserved for 3D mesh viewports.
    static let meshCanvas     = Color(hex: 0x000000)

    // MARK: Ink

    static let ink            = Color(hex: 0x0A0A0F)   // near-black
    static let inkDim         = Color.black.opacity(0.62)
    static let inkMuted       = Color.black.opacity(0.40)

    // MARK: Facet hues — one per 72° sector of the Aesthetic Wheel

    // Five facet hues — one per facet of Dr Nikolis's FAS.
    // Keep in sync with `facetHues` in web/lib/tokens.ts (web is source of truth).
    static let domainSkinQuality = Color(hex: 0xC9BBEE) // lavender
    static let domainFacialShape = Color(hex: 0xA6B4DD) // periwinkle
    static let domainProportions = Color(hex: 0x7A8094) // slate
    static let domainProportionsFill = Color(hex: 0x3F4456) // darker slate for fills
    static let domainSymmetry    = Color(hex: 0xE9B5E0) // magenta-pink
    static let domainExpression  = Color(hex: 0xF2C9A1) // peach

    // MARK: Status — semantic colours for warning / confirmation states.
    //
    // Use these (never facet hues) for any non-facet meaning: facet hues
    // exclusively encode FAS facets, so borrowing one for a status reads as a
    // facet reference.
    static let warning    = Color(hex: 0xB45309)   // amber foreground / icon
    static let warningBg  = Color(hex: 0xFEF3C7)   // amber banner background
    static let warningInk = Color(hex: 0x78350F)   // text on warningBg
    static let positive   = Color(hex: 0x3E7C4F)   // confirmation ("picked", saved)
    static let negative   = Color(hex: 0x9B3B2E)   // destructive / failure

    /// Visit-over-visit change status. Desaturated so they read as annotations,
    /// not alarms; worsened must read heavier than improved.
    static let statusWorsened = negative
    static let statusImproved = positive

    // MARK: Geometry

    static let radiusCard:   CGFloat = 16
    static let radiusSheet:  CGFloat = 24
    static let radiusButton: CGFloat = 12
    static let hairlineWidth: CGFloat = 1
}

// MARK: - Domain → hue

extension FaceDomain {
    var hue: Color {
        switch self {
        case .skinQuality: return Theme.domainSkinQuality
        case .facialShape: return Theme.domainFacialShape
        case .proportions: return Theme.domainProportions
        case .symmetry:    return Theme.domainSymmetry
        case .expression:  return Theme.domainExpression
        }
    }

    /// Foreground hue for fill-style backgrounds (Proportions' slate needs the darker variant).
    var fillHue: Color {
        switch self {
        case .proportions: return Theme.domainProportionsFill
        default:           return hue
        }
    }
}

// MARK: - Severity → opacity ramp inside a domain

extension MetricResult.Severity {
    /// Ring index 1..3 mirroring Dr Nikolis's framework. `.normal` returns 0.
    var ringIndex: Int {
        switch self {
        case .normal:       return 0
        case .mild:         return 1
        case .moderate:     return 2
        case .significant:  return 3
        }
    }

    /// Opacity used to tint a domain hue at this severity. 0 for `.normal`.
    var ringOpacity: Double {
        switch self {
        case .normal:       return 0.0
        case .mild:         return 0.38
        case .moderate:     return 0.64
        case .significant:  return 1.0
        }
    }

    /// The colour shown for this severity within a given domain.
    func color(in domain: FaceDomain) -> Color {
        guard self != .normal else { return Theme.inkMuted }
        return domain.hue.opacity(ringOpacity)
    }
}

// MARK: - Hex initializer

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
