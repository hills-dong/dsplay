#if os(macOS)
import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let item: NSStatusItem
    private let popover: NSPopover
    private let onShowWindow: () -> Void

    init(engine: PlaybackEngine, synology: SynologyClient, state: PlayerState,
         onShowWindow: @escaping () -> Void) {
        self.onShowWindow = onShowWindow

        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        self.popover = NSPopover()
        self.popover.behavior = .transient
        self.popover.animates = true

        super.init()

        if let button = item.button {
            button.image = Self.loadStatusItemImage()
            button.toolTip = "DSPlay"
            button.target = self
            button.action = #selector(handleClick(_:))
        }

        let view = MiniPlayerView(
            state: state,
            engine: engine,
            synology: synology,
            onShowWindow: { [weak self] in
                self?.closePopover()
                self?.onShowWindow()
            },
            onQuit: { NSApp.terminate(nil) }
        )
        self.popover.contentViewController = NSHostingController(rootView: view)
        self.popover.delegate = self
    }

    /// Loads StatusItem.png from whichever bundle layout we're running in.
    /// `Bundle.module` is a trapping accessor, so it must only be evaluated as
    /// a last resort, never eagerly.
    private static func loadStatusItemImage() -> NSImage? {
        func makeImage(_ url: URL) -> NSImage? {
            guard let img = NSImage(contentsOf: url) else { return nil }
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        }

        // 1. swift-bundler layout: nested SwiftPM bundle.
        if let url = Bundle.main
            .url(forResource: "DSPlay_DSPlay", withExtension: "bundle")
            .flatMap({ Bundle(url: $0) })?
            .url(forResource: "StatusItem", withExtension: "png"),
           let img = makeImage(url) {
            return img
        }
        // 2. Flat in Bundle.main.
        if let url = Bundle.main.url(forResource: "StatusItem", withExtension: "png"),
           let img = makeImage(url) {
            return img
        }
        // 3. SwiftPM module accessor — last resort. `Bundle.module` is
        //    synthesised only by SwiftPM (swift-bundler builds); it does not
        //    exist in the Xcode Mac App Store target, so gate on SWIFT_PACKAGE.
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "StatusItem", withExtension: "png"),
           let img = makeImage(url) {
            return img
        }
        #endif

        NSLog("[DSPlay] StatusItem.png not found in any bundle path; falling back to SF Symbol")
        let fallback = NSImage(systemSymbolName: "music.note", accessibilityDescription: "DSPlay")
        fallback?.isTemplate = true
        return fallback
    }

    @objc private func handleClick(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = item.button else { return }
        // Anchor the popover to the status item BEFORE activating the app.
        // Calling NSApp.activate(_:) first makes AppKit lay the popover out
        // against a stale status-button frame. Show first, then activate to
        // take key focus.
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}

extension StatusItemController: NSPopoverDelegate {
    // No teardown needed — @Observable PlayerState drives the view directly,
    // there is no polling timer to stop (unlike the old MiniPlayerModel).
}
#endif
