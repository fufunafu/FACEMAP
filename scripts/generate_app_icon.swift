// generate_app_icon.swift
// FaceMap app icon generator — FAS wheel brand mark.
//
// Emits three 1024x1024 PNGs (light / dark / tinted) into
// FaceMap/Assets.xcassets/AppIcon.appiconset.
//
// Geometry mirrors web/components/brand-mark.tsx:
//   - full-bleed circle of radius 15/16 of half-width, centered
//   - central hub of radius 4/15 of the outer radius
//   - five 72° sectors starting at 12 o'clock, clockwise
//   - gaps between sectors ~2.5% of canvas width, in the background color
//   - thin ink ring (0x0A0A0F, ~3% of canvas width) around the outer circle
//   - hub filled with the background color plus a hairline 0x0A0A0F ring
//
// Run from the repo root (or anywhere — paths are resolved from this file):
//   swift scripts/generate_app_icon.swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Constants

let canvas: CGFloat = 1024
let center = CGPoint(x: canvas / 2, y: canvas / 2)
let outerRadius = (canvas / 2) * 15 / 16          // 480
let hubRadius = outerRadius * 4 / 15              // 128
let gapWidth = canvas * 0.025                     // ~25.6 — slit between sectors
let inkRingWidth = canvas * 0.03                  // ~30.7 — outer ink ring
let hairlineWidth = canvas * 0.004                // ~4.1  — hub hairline ring

let ink: UInt32 = 0x0A0A0F
let lightBackground: UInt32 = 0xFAFAFA
let darkBackground: UInt32 = 0x0A0A0F

// Unified FAS facet palette, clockwise from 12 o'clock.
let facetPalette: [UInt32] = [0xC9BBEE, 0xA6B4DD, 0x7A8094, 0xE9B5E0, 0xF2C9A1]

// Tinted (monochrome) variant: white at stepped opacities, clockwise from 12 o'clock.
let tintedOpacities: [CGFloat] = [0.38, 0.52, 0.64, 0.82, 1.0]

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: colorSpace,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            alpha,
        ]
    )!
}

struct Variant {
    let filename: String
    /// nil — transparent canvas (tinted variant).
    let background: UInt32?
    let sectorColors: [CGColor]
    /// Draw the outer ink ring and hub hairline (skipped for the tinted variant).
    let drawInkRings: Bool
}

let variants: [Variant] = [
    Variant(
        filename: "AppIcon-Light-1024.png",
        background: lightBackground,
        sectorColors: facetPalette.map { rgb($0) },
        drawInkRings: true
    ),
    Variant(
        filename: "AppIcon-Dark-1024.png",
        background: darkBackground,
        sectorColors: facetPalette.map { rgb($0) },
        drawInkRings: true
    ),
    Variant(
        filename: "AppIcon-Tinted-1024.png",
        background: nil,
        sectorColors: tintedOpacities.map { rgb(0xFFFFFF, alpha: $0) },
        drawInkRings: false
    ),
]

// MARK: - Rendering

func render(_ variant: Variant) -> CGImage {
    let context = CGContext(
        data: nil,
        width: Int(canvas),
        height: Int(canvas),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // CGContext bitmap space is y-up; visually clockwise from 12 o'clock means
    // decreasing angle from π/2.
    let sectorSweep = 2 * CGFloat.pi / 5

    if let background = variant.background {
        context.setFillColor(rgb(background))
        context.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
    }

    // Five 72° sectors, clockwise from 12 o'clock.
    for index in 0..<5 {
        let start = CGFloat.pi / 2 - CGFloat(index) * sectorSweep
        let end = start - sectorSweep
        context.beginPath()
        context.move(to: center)
        context.addArc(
            center: center,
            radius: outerRadius,
            startAngle: start,
            endAngle: end,
            clockwise: true
        )
        context.closePath()
        context.setFillColor(variant.sectorColors[index])
        context.fillPath()
    }

    // Gap slits between sectors, in the background color (erased on tinted).
    context.setLineWidth(gapWidth)
    context.setLineCap(.butt)
    if let background = variant.background {
        context.setStrokeColor(rgb(background))
    } else {
        context.setBlendMode(.clear)
    }
    for index in 0..<5 {
        let angle = CGFloat.pi / 2 - CGFloat(index) * sectorSweep
        context.beginPath()
        context.move(to: center)
        context.addLine(to: CGPoint(
            x: center.x + outerRadius * cos(angle),
            y: center.y + outerRadius * sin(angle)
        ))
        context.strokePath()
    }
    context.setBlendMode(.normal)

    // Outer ink ring.
    if variant.drawInkRings {
        context.setStrokeColor(rgb(ink))
        context.setLineWidth(inkRingWidth)
        context.strokeEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))
    }

    // Hub: background fill (or punched out on tinted) plus hairline ink ring.
    let hubRect = CGRect(
        x: center.x - hubRadius,
        y: center.y - hubRadius,
        width: hubRadius * 2,
        height: hubRadius * 2
    )
    if let background = variant.background {
        context.setFillColor(rgb(background))
        context.fillEllipse(in: hubRect)
    } else {
        context.setBlendMode(.clear)
        context.fillEllipse(in: hubRect)
        context.setBlendMode(.normal)
    }
    if variant.drawInkRings {
        context.setStrokeColor(rgb(ink))
        context.setLineWidth(hairlineWidth)
        context.strokeEllipse(in: hubRect)
    }

    return context.makeImage()!
}

// MARK: - Output

let scriptURL = URL(fileURLWithPath: #filePath)
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let appIconSetURL = repoRoot
    .appendingPathComponent("FaceMap")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

try FileManager.default.createDirectory(
    at: appIconSetURL,
    withIntermediateDirectories: true
)

for variant in variants {
    let image = render(variant)
    let destinationURL = appIconSetURL.appendingPathComponent(variant.filename)
    guard let destination = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fatalError("Could not create PNG destination at \(destinationURL.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(destinationURL.path)")
    }
    print("Wrote \(variant.filename) (\(image.width)x\(image.height))")
}
