import SwiftUI

/// Circular four-quadrant FaceMap logo. Mirrors web/components/brand-mark.tsx
/// so the iOS app, marketing site, and PDF exports share one visual identity.
///
/// Quadrants (clockwise from 12 o'clock):
///   - top-right    → Theme.domainOptical    (slate)
///   - bottom-right → Theme.domainStructural (periwinkle)
///   - bottom-left  → Theme.domainSymmetry   (magenta-pink)
///   - top-left     → Theme.domainMechanical (lavender)
struct LogoMark: View {
    let size: CGFloat

    init(size: CGFloat = 32) { self.size = size }

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outerR = s / 2 - max(1, s * 0.03)
            let innerR = outerR * (4.0 / 15.0) // matches web hub ratio (r=4 of r=15)

            // Quadrant slices — start angles in SwiftUI convention
            // (0° = 3 o'clock, +clockwise because y is down on screen).
            let slices: [(start: Angle, end: Angle, color: Color)] = [
                (.degrees(-90), .degrees(0),   Theme.domainProportions), // top-right
                (.degrees(0),   .degrees(90),  Theme.domainFacialShape), // bottom-right
                (.degrees(90),  .degrees(180), Theme.domainSymmetry),    // bottom-left
                (.degrees(180), .degrees(270), Theme.domainSkinQuality), // top-left
            ]

            for slice in slices {
                var path = Path()
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: outerR,
                    startAngle: slice.start,
                    endAngle: slice.end,
                    clockwise: false
                )
                path.closeSubpath()
                context.fill(path, with: .color(slice.color))
            }

            // Outer hairline
            let outerRing = Path(ellipseIn: CGRect(
                x: center.x - outerR,
                y: center.y - outerR,
                width: outerR * 2,
                height: outerR * 2
            ))
            context.stroke(outerRing, with: .color(Theme.hairline), lineWidth: 1)

            // Centre hub (canvas-coloured, mirrors the web mark)
            let hub = Path(ellipseIn: CGRect(
                x: center.x - innerR,
                y: center.y - innerR,
                width: innerR * 2,
                height: innerR * 2
            ))
            context.fill(hub, with: .color(Theme.canvas))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("FaceMap")
    }
}

#Preview {
    VStack(spacing: 24) {
        LogoMark(size: 96)
        LogoMark(size: 48)
        LogoMark(size: 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.canvas)
}
