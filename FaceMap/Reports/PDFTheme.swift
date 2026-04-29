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

    static let pageWidth:  CGFloat = 595   // A4 portrait, 72dpi
    static let pageHeight: CGFloat = 842

    static let margin:    CGFloat = 36
    static let gutter:    CGFloat = 18
}
