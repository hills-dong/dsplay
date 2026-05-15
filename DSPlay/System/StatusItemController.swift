import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let item: NSStatusItem
    private let popover: NSPopover
    private let model: MiniPlayerModel
    private let onShowWindow: () -> Void

    init(engine: PlaybackEngine, synology: SynologyClient, onShowWindow: @escaping () -> Void) {
        self.onShowWindow = onShowWindow
        self.model = MiniPlayerModel(engine: engine, synology: synology)

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
            model: model,
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
    /// Mirrors the multi-path strategy in WebViewController.resolveWebDistDirectory.
    private static func loadStatusItemImage() -> NSImage? {
        let candidates: [URL?] = [
            // 1. swift-bundler layout: nested SwiftPM bundle.
            Bundle.main
                .url(forResource: "DSPlay_DSPlay", withExtension: "bundle")
                .flatMap { Bundle(url: $0) }?
                .url(forResource: "StatusItem", withExtension: "png"),
            // 2. SwiftPM module accessor (used by `swift run` / tests).
            Bundle.module.url(forResource: "StatusItem", withExtension: "png"),
            // 3. Flat in Bundle.main.
            Bundle.main.url(forResource: "StatusItem", withExtension: "png"),
        ]
        for url in candidates.compactMap({ $0 }) {
            if let img = NSImage(contentsOf: url) {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                return img
            }
        }
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
        // .accessory apps don't always own the active app, so activate so the
        // popover can become key and receive keyboard input.
        NSApp.activate(ignoringOtherApps: true)
        model.start()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}

extension StatusItemController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        model.stop()
    }
}
