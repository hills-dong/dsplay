import AppKit
import Foundation

// Renders a single 1024x1024 PNG (black rounded square + white music note)
// to the path given as the first argument. sips/iconutil downstream handle
// scaling + icns packaging.

let outPath = CommandLine.arguments[1]
let size: CGFloat = 1024

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let bg = NSBezierPath(
    roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
    xRadius: size * 0.22,
    yRadius: size * 0.22
)
NSColor.black.setFill()
bg.fill()

let text = "♪" as NSString
let font = NSFont.systemFont(ofSize: size * 0.62, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let tsize = text.size(withAttributes: attrs)
text.draw(
    at: NSPoint(
        x: (size - tsize.width) / 2,
        y: (size - tsize.height) / 2 - size * 0.05
    ),
    withAttributes: attrs
)

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))
