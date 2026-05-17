import AppKit
import Foundation

// Renders one PNG for a brand-mark variant. The bash orchestrator
// (scripts/make-icon.sh) calls this repeatedly and packages the results.
//
// Usage:
//   swift scripts/make-icon.swift --variant {app|ios|statusbar} \
//                                 --size N --output PATH
//
//  app       : macOS app icon — squircle-radius rounded rect, red brand
//              gradient, white rounded "DS" + white accent dot. A small
//              inset is left around the rounded rect (macOS convention).
//  ios       : iOS app icon — identical mark but FULL-BLEED square with no
//              rounded corners and no inset (springboard masks the squircle
//              itself).
//  statusbar : transparent background, monochrome black "DS" — macOS menu
//              bar template image (the system tints it).
//
// The mark matches the current Apple-Music-style UI: the brand red accent
// (systemRed family) and the bold "DS." wordmark with its signature dot.
//
// Coordinates are TOP-DOWN (lockFocusFlipped(true)); constants are fractions
// of the canvas — tweak and re-run.

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
    FileHandle.standardError.write("usage: --variant {app|ios|statusbar} --size N --output PATH\n".data(using: .utf8)!)
    exit(2)
}
let size = CGFloat(sizeArg)

// ----- font: bold rounded (SF Pro Rounded), matching the clean UI -----
func roundedBold(_ pointSize: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: pointSize, weight: .heavy)
    if let rd = base.fontDescriptor.withDesign(.rounded),
       let f = NSFont(descriptor: rd, size: pointSize) { return f }
    return base
}

// ----- brand colours (the red accent of the current UI) -----
let redTop = NSColor(red: 0xFF/255.0, green: 0x45/255.0, blue: 0x3A/255.0, alpha: 1) // systemRed-ish
let redBot = NSColor(red: 0xD2/255.0, green: 0x00/255.0, blue: 0x1E/255.0, alpha: 1) // deeper
let white  = NSColor.white
let ink    = NSColor(red: 0x11/255.0, green: 0x11/255.0, blue: 0x11/255.0, alpha: 1)

// ----- helpers (top-down coords) -----

/// Draws "DS" + a trailing dot as one group, centred on (cx, cy).
func drawWordmark(cx: CGFloat, cy: CGFloat, fontSize: CGFloat,
                  color: NSColor, dotColor: NSColor, withDot: Bool) {
    let font = roundedBold(fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: -fontSize * 0.03 as NSNumber,
    ]
    let text = "DS" as NSString
    let bbox = text.size(withAttributes: attrs)

    let dotR: CGFloat = withDot ? fontSize * 0.085 : 0
    let dotGap: CGFloat = withDot ? fontSize * 0.10 : 0
    let groupW = bbox.width + dotGap + dotR * 2
    let originX = cx - groupW / 2
    // The glyph box includes the descender slack; nudge up so the visible
    // letters sit centred on cy.
    let originY = cy - bbox.height / 2 + font.descender / 2
    text.draw(at: NSPoint(x: originX, y: originY), withAttributes: attrs)

    if withDot {
        let dotCX = originX + bbox.width + dotGap + dotR
        // Sit the dot on the letter baseline (≈ bottom of the cap height).
        let dotCY = cy + bbox.height / 2 + font.descender / 2 - dotR
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: dotCX - dotR, y: dotCY - dotR,
                                    width: dotR * 2, height: dotR * 2)).fill()
    }
}

func fillRedGradient(in path: NSBezierPath) {
    path.addClip()
    let g = NSGradient(starting: redTop, ending: redBot)!
    g.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)
}

// ----- canvas (flipped → top-down coords) -----
// Proven approach: lockFocusFlipped on an NSImage. (A hand-rolled
// NSBitmapImageRep context rendered all-black, so don't reintroduce it.)
// Exact output pixel size + any alpha flattening is handled downstream by
// make-icon.sh (sips), so we only need correct ART here.
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocusFlipped(true)
let ctx = NSGraphicsContext.current

switch variant {
case "app":
    // macOS: rounded rect with a small inset, transparent corners.
    let inset = size * 0.06
    let r = (size - inset * 2) * 0.2237      // Apple squircle ratio
    let bg = NSBezierPath(roundedRect:
        NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2),
        xRadius: r, yRadius: r)
    ctx?.saveGraphicsState()
    fillRedGradient(in: bg)
    ctx?.restoreGraphicsState()
    drawWordmark(cx: size * 0.5, cy: size * 0.5, fontSize: size * 0.40,
                 color: white, dotColor: white, withDot: true)

case "ios":
    // iOS: full-bleed square (springboard masks the squircle).
    ctx?.saveGraphicsState()
    fillRedGradient(in: NSBezierPath(rect:
        NSRect(x: 0, y: 0, width: size, height: size)))
    ctx?.restoreGraphicsState()
    drawWordmark(cx: size * 0.5, cy: size * 0.5, fontSize: size * 0.42,
                 color: white, dotColor: white, withDot: true)

case "statusbar":
    // Monochrome template — no dot (menu bar images are 1-bit-ish).
    drawWordmark(cx: size * 0.5, cy: size * 0.52, fontSize: size * 0.62,
                 color: ink, dotColor: ink, withDot: false)

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
