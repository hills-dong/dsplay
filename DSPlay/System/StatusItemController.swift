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
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "DSPlay")
            button.image?.isTemplate = true
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
