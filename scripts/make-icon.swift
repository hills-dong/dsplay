import AppKit
import Foundation

// Renders a single PNG for one of three brand variants. The bash
// orchestrator calls this multiple times, then downscales / packages as
// needed.
//
// Usage:
//   swift scripts/make-icon.swift --variant {app-large|app-small|statusbar} \
//                                 --size N --output PATH
//
//  app-large : square paper-on-rounded-rect with two hairline rules + a
//              big serif "D" + a red period. Used as the master for the
//              128/256/512/1024 slots of the .icns iconset.
//  app-small : same square + paper bg but the hairlines are dropped and
//              the "D." is enlarged so the dot still reads at 16px.
//              Used as the master for the 16/32/64 slots.
//  statusbar : transparent background, plain black serif "D" (no dot —
//              menu bar template images are monochrome). Used as the
//              menu bar icon.
//
// All coordinates below are TOP-DOWN (y=0 is at the top of the canvas),
// because `lockFocusFlipped(true)` sets up a flipped graphics context.
// Numeric constants are fractions of 1024 — tweak them and re-run to taste.

// ----- argument parsing -----
var variant: String?
var sizeArg: Double?
var outPath: String?
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next() {
    switch arg {
    case "--variant":  variant = args.next()
    case "--size":     sizeArg = args.next().flatMap { Double($0) }
    case "--output":   outPath = args.next()
    default:           break
    }
}
guard let variant, let sizeArg, let outPath else {
    FileHandle.standardError.write("usage: --variant {app-large|app-small|statusbar} --size N --output PATH\n".data(using: .utf8)!)
    exit(2)
}
let size = CGFloat(sizeArg)

// ----- font resolution -----
func serifBold(_ pointSize: CGFloat) -> NSFont {
    // 1. Newsreader (the typeface the web UI uses) if installed.
    if let f = NSFont(name: "Newsreader-Bold", size: pointSize) { return f }
    if let f = NSFont(name: "Newsreader", size: pointSize) { return f }
    // 2. New York (macOS system serif since Big Sur).
    if let f = NSFont(name: "NewYork-Bold", size: pointSize) { return f }
    // 3. Derive a serif from the system font descriptor.
    let systemBold = NSFont.systemFont(ofSize: pointSize, weight: .bold)
    if let serif = systemBold.fontDescriptor.withDesign(.serif),
       let f = NSFont(descriptor: serif, size: pointSize) { return f }
    // 4. Last-resort: system bold (sans-serif but the renderer will still
    // produce something visible — the operator should install Newsreader).
    return systemBold
}

// ----- colour tokens (match web/src/styles/theme.css) -----
let ink    = NSColor(red: 0x11/255.0, green: 0x11/255.0, blue: 0x11/255.0, alpha: 1.0)
let paper  = NSColor(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xF7/255.0, alpha: 1.0)
let accent = NSColor(red: 0xC4/255.0, green: 0x30/255.0, blue: 0x2B/255.0, alpha: 1.0)

// ----- helpers (top-down coordinates) -----

/// Draws a serif "D" so that the bounding box of the glyph is centred on
/// (centerX, centerY). The "D" has empty space below the baseline
/// (descender area), so to make the visible glyph land at centerY we
/// shift the box up by half the descender height.
func drawSerifD(centerX: CGFloat, centerY: CGFloat, fontSize: CGFloat, color: NSColor) {
    let font = serifBold(fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: -fontSize * 0.02 as NSNumber,
    ]
    let text = "D" as NSString
    let bbox = text.size(withAttributes: attrs)
    let descender = font.descender   // negative
    let origin = NSPoint(
        x: centerX - bbox.width / 2,
        y: centerY - bbox.height / 2 + descender / 2
    )
    text.draw(at: origin, withAttributes: attrs)
}

func drawDot(centerX: CGFloat, centerY: CGFloat, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: centerX - radius, y: centerY - radius,
        width: radius * 2, height: radius * 2
    )).fill()
}

func drawHairline(yTop: CGFloat, inset: CGFloat, thickness: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(rect: NSRect(
        x: inset, y: yTop, width: size - inset * 2, height: thickness
    )).fill()
}

// ----- canvas (flipped → top-down coords) -----
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocusFlipped(true)

switch variant {
case "app-large":
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
        xRadius: size * 0.22, yRadius: size * 0.22
    )
    paper.setFill(); bgPath.fill()

    let ruleInset = size * (100.0/1024.0)
    let ruleThickness = max(1, size * (3.0/1024.0))
    drawHairline(yTop: size * (180.0/1024.0), inset: ruleInset, thickness: ruleThickness, color: ink)
    drawHairline(yTop: size * (841.0/1024.0), inset: ruleInset, thickness: ruleThickness, color: ink)

    drawSerifD(
        centerX: size * 0.40,
        centerY: size * 0.52,
        fontSize: size * (760.0/1024.0),
        color: ink
    )
    drawDot(
        centerX: size * 0.74,
        centerY: size * 0.72,
        radius:  size * (68.0/1024.0),
        color: accent
    )

case "app-small":
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
        xRadius: size * 0.22, yRadius: size * 0.22
    )
    paper.setFill(); bgPath.fill()

    drawSerifD(
        centerX: size * 0.40,
        centerY: size * 0.52,
        fontSize: size * (900.0/1024.0),
        color: ink
    )
    drawDot(
        centerX: size * 0.76,
        centerY: size * 0.74,
        radius:  size * (90.0/1024.0),
        color: accent
    )

case "statusbar":
    drawSerifD(
        centerX: size / 2,
        centerY: size * 0.50,
        fontSize: size * 0.88,
        color: ink
    )

default:
    img.unlockFocus()
    FileHandle.standardError.write("unknown variant: \(variant)\n".data(using: .utf8)!)
    exit(2)
}

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))
