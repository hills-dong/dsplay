import AppKit

/// A transparent overlay placed at the top of the WKWebView area that catches
/// mouseDown and asks the window to drag itself. WKWebView's `-webkit-app-region: drag`
/// CSS hint is unreliable on macOS, so we provide drag-by-AppKit instead.
///
/// Sized via Auto Layout to span the full window width and the standard
/// titlebar height (28pt). Sits above the WebView in the z-order, intercepting
/// clicks in that strip — clicks lower than the strip pass through to the
/// WebView normally.
final class TitlebarDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        // On macOS, the standard click-and-drag-to-move gesture is implemented
        // by NSWindow.performDrag(with:). This works from any subview.
        self.window?.performDrag(with: event)
    }

    // Allow double-click to zoom (standard titlebar behavior).
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            self.window?.performZoom(nil)
        }
    }
}
