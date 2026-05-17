import SwiftUI

extension View {
    /// No-op — on macOS slim scrollers are forced globally (see
    /// `ScrollerTheming`); on iOS scrolling uses the native overlay indicator.
    func thinScrollbars() -> some View { self }
}

#if os(macOS)
import AppKit
import ObjectiveC

/// Always-visible, very thin, faint scroller (no track slot).
final class ThinScroller: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool { false }
    override class func scrollerWidth(for controlSize: NSControl.ControlSize,
                                      scrollerStyle: NSScroller.Style) -> CGFloat { 9 }

    override func drawKnobSlot(in slotRect: NSRect, highlight: Bool) { /* none */ }

    override func drawKnob() {
        let k = rect(for: .knob)
        let vertical = bounds.height > bounds.width
        let t: CGFloat = 4
        let pad: CGFloat = 2
        let r: NSRect = vertical
            ? NSRect(x: bounds.midX - t / 2, y: k.minY + pad,
                     width: t, height: max(20, k.height - pad * 2))
            : NSRect(x: k.minX + pad, y: bounds.midY - t / 2,
                     width: max(20, k.width - pad * 2), height: t)
        NSColor.secondaryLabelColor.withAlphaComponent(0.30).setFill()
        NSBezierPath(roundedRect: r, xRadius: t / 2, yRadius: t / 2).fill()
    }

    override func draw(_ dirtyRect: NSRect) {
        drawKnob()
    }
}

enum ScrollerTheming {
    private static var done = false

    /// Swizzle so every NSScrollView, from its first frame, uses the legacy
    /// (always-visible) style with our slim faint `ThinScroller` — no flash,
    /// no polling, not auto-hidden.
    static func enableOverlayScrollers() {
        guard !done else { return }
        done = true
        swap(#selector(getter: NSScrollView.scrollerStyle),
             #selector(NSScrollView.dsplay_style))
        swap(#selector(getter: NSScrollView.verticalScroller),
             #selector(NSScrollView.dsplay_vScroller))
        swap(#selector(getter: NSScrollView.horizontalScroller),
             #selector(NSScrollView.dsplay_hScroller))
    }

    private static func swap(_ a: Selector, _ b: Selector) {
        guard let m1 = class_getInstanceMethod(NSScrollView.self, a),
              let m2 = class_getInstanceMethod(NSScrollView.self, b) else { return }
        method_exchangeImplementations(m1, m2)
    }
}

private extension NSScrollView {
    @objc func dsplay_style() -> NSScroller.Style { .legacy }

    @objc func dsplay_vScroller() -> NSScroller? {
        let cur = dsplay_vScroller()          // original impl after exchange
        if cur is ThinScroller { return cur }
        let s = ThinScroller(); verticalScroller = s; return s
    }

    @objc func dsplay_hScroller() -> NSScroller? {
        let cur = dsplay_hScroller()
        if cur is ThinScroller { return cur }
        let s = ThinScroller(); horizontalScroller = s; return s
    }
}
#endif
