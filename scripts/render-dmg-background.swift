#!/usr/bin/env swift

import AppKit
import Foundation

let canvasSize = NSSize(width: 760, height: 520)
let outputURL: URL

if CommandLine.arguments.count > 1 {
    outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
} else {
    outputURL = URL(fileURLWithPath: "Distribution/DMG/background.png")
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineSpacing: CGFloat = 2
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = lineSpacing
    NSString(string: text).draw(
        with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Failed to create DMG background canvas\n", stderr)
    exit(1)
}
bitmap.size = canvasSize
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let fullRect = NSRect(origin: .zero, size: canvasSize)
let gradient = NSGradient(colors: [color(0xF9FAFD), color(0xEEF3FF)])!
gradient.draw(in: fullRect, angle: -90)

// Soft brand glow behind the drag area.
let glowPath = NSBezierPath(ovalIn: NSRect(x: 240, y: 260, width: 280, height: 180))
color(0x5B6CFF, alpha: 0.07).setFill()
glowPath.fill()

drawText(
    "Install MacSweep",
    in: NSRect(x: 40, y: 462, width: 680, height: 34),
    font: .systemFont(ofSize: 26, weight: .bold),
    color: color(0x171923),
    alignment: .center
)
drawText(
    "Drag MacSweep to Applications",
    in: NSRect(x: 40, y: 434, width: 680, height: 24),
    font: .systemFont(ofSize: 14, weight: .medium),
    color: color(0x667085),
    alignment: .center
)

// Arrow between the Finder-managed MacSweep and Applications icons.
let arrowColor = color(0x536DFE, alpha: 0.85)
arrowColor.setStroke()
let arrow = NSBezierPath()
arrow.lineWidth = 4
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: 300, y: 344))
arrow.line(to: NSPoint(x: 460, y: 344))
arrow.stroke()

arrowColor.setFill()
let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 460, y: 344))
arrowHead.line(to: NSPoint(x: 444, y: 355))
arrowHead.line(to: NSPoint(x: 444, y: 333))
arrowHead.close()
arrowHead.fill()

// First-launch guidance panel.
let panelRect = NSRect(x: 38, y: 35, width: 684, height: 198)
let panel = NSBezierPath(roundedRect: panelRect, xRadius: 16, yRadius: 16)
color(0xFFFFFF, alpha: 0.92).setFill()
panel.fill()
color(0x536DFE, alpha: 0.14).setStroke()
panel.lineWidth = 1
panel.stroke()

drawText(
    "First launch on macOS",
    in: NSRect(x: 62, y: 194, width: 636, height: 24),
    font: .systemFont(ofSize: 15, weight: .semibold),
    color: color(0x27314D)
)
drawText(
    "MacSweep is an open-source, ad-hoc-signed build and is not Apple-notarized.",
    in: NSRect(x: 62, y: 158, width: 636, height: 32),
    font: .systemFont(ofSize: 12, weight: .medium),
    color: color(0x344054)
)
drawText(
    "On first launch, try to open MacSweep once, then use System Settings → Privacy & Security → Open Anyway.",
    in: NSRect(x: 62, y: 105, width: 636, height: 48),
    font: .systemFont(ofSize: 12, weight: .regular),
    color: color(0x475467),
    lineSpacing: 3
)
drawText(
    "Inside onboarding, you can continue with limited access or optionally grant Full Disk Access for more complete scans.",
    in: NSRect(x: 62, y: 51, width: 636, height: 48),
    font: .systemFont(ofSize: 12, weight: .regular),
    color: color(0x475467),
    lineSpacing: 3
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to render DMG background\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
