#if os(macOS)
import Cocoa
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController {

    convenience init(appModel: AppModel, uiState: UIState) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // Only the title-bar strip drags the window — dragging in lists/empty
        // content should not move it.
        window.isMovableByWindowBackground = false
        // Translucent so the SwiftUI AppBackground vibrancy + the frosted
        // sidebar / player bar render the Apple-Music glass look. The content
        // column itself paints a near-opaque adaptive surface, so only the
        // chrome is blurred (no whole-tree reblend → still smooth).
        window.isOpaque = false
        window.backgroundColor = .clear

        window.setFrameAutosaveName("DSPlayMainWindow")
        if !window.setFrameUsingName("DSPlayMainWindow") {
            window.center()
        }
        // The autosaved frame can be stale / off-screen (e.g. saved on a
        // display that's now disconnected). If it doesn't substantially
        // overlap any visible screen, recenter on the main screen.
        let onScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersection(window.frame).size.width > 200 &&
            screen.visibleFrame.intersection(window.frame).size.height > 200
        }
        if !onScreen { window.center() }

        self.init(window: window)
        installContent(appModel: appModel, uiState: uiState)
    }

    private func installContent(appModel: AppModel, uiState: UIState) {
        guard let window, let contentView = window.contentView else { return }

        // Classic vibrant window: ONE full-window NSVisualEffectView as the
        // real backing (behind-window blur of the desktop, adaptive
        // light/dark) with a fully transparent SwiftUI host on top. The
        // SwiftUI layer only paints semi-opaque scrims for readability, so
        // the frost is genuinely visible everywhere.
        let vibrancy = NSVisualEffectView()
        vibrancy.material = .sidebar
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active           // stay frosted even when inactive
        vibrancy.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vibrancy)

        let root = RootView()
            .environment(appModel)
            .environment(uiState)
        let host = NSHostingView(rootView: root)
        host.translatesAutoresizingMaskIntoConstraints = false
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(host)
        NSLayoutConstraint.activate([
            vibrancy.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            vibrancy.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            vibrancy.topAnchor.constraint(equalTo: contentView.topAnchor),
            vibrancy.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
#endif
