#if os(macOS)
import SwiftUI
import AppKit

/// Real AppKit vibrancy usable as a SwiftUI background. Unlike SwiftUI's
/// `.regularMaterial` (which blurs only SwiftUI content behind it — nothing,
/// when the hosting view is transparent), this samples behind the window so
/// the sidebar / player bar get a true frosted-glass look in both modes.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .followsWindowActiveState
        v.isEmphasized = true
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}

extension View {
    /// Frosted-glass background clipped to a rounded rect (0 = plain rect).
    func glassBackground(_ material: NSVisualEffectView.Material = .sidebar,
                         cornerRadius: CGFloat = 0) -> some View {
        background(
            VisualEffectBackground(material: material)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius,
                                            style: .continuous))
        )
    }
}
#endif
