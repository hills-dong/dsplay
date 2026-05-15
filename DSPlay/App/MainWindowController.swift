import Cocoa

@MainActor
final class MainWindowController: NSWindowController {
    let webViewController = WebViewController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true

        window.setFrameAutosaveName("DSPlayMainWindow")
        if !window.setFrameUsingName("DSPlayMainWindow") {
            window.center()
        }

        self.init(window: window)
        installContent()
    }

    private func installContent() {
        guard let window, let contentView = window.contentView else { return }

        let vibrancy = NSVisualEffectView(frame: contentView.bounds)
        vibrancy.autoresizingMask = [.width, .height]
        vibrancy.material = .underWindowBackground
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .followsWindowActiveState

        let tint = NSView(frame: vibrancy.bounds)
        tint.autoresizingMask = [.width, .height]
        tint.wantsLayer = true
        let tintLayer = CALayer()
        tintLayer.backgroundColor = NSColor(
            srgbRed: 0xFA / 255.0,
            green:   0xFA / 255.0,
            blue:    0xF7 / 255.0,
            alpha:   0.92
        ).cgColor
        tint.layer = tintLayer

        vibrancy.addSubview(tint)
        contentView.addSubview(vibrancy)

        let wv = webViewController.view
        wv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(wv)
        NSLayoutConstraint.activate([
            wv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            wv.topAnchor.constraint(equalTo: contentView.topAnchor),
            wv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Transparent strip across the top of the window — catches mouseDown
        // so the user can drag the window from the titlebar area regardless of
        // whether the WebView's `-webkit-app-region: drag` CSS works (which is
        // unreliable in WKWebView on macOS).
        let dragStrip = TitlebarDragView()
        dragStrip.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dragStrip)
        NSLayoutConstraint.activate([
            dragStrip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dragStrip.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dragStrip.topAnchor.constraint(equalTo: contentView.topAnchor),
            dragStrip.heightAnchor.constraint(equalToConstant: 28),
        ])
    }
}
