import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: MainWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Eagerly build the window controller so PlaybackEngine + SynologyClient
        // exist for the status-bar mini player, but don't show the window — this
        // is a menu-bar-resident app, the status item is the entry point.
        let wc = MainWindowController()
        windowController = wc

        let engine = wc.webViewController.playback
        let synology = wc.webViewController.synology
        statusItemController = StatusItemController(
            engine: engine,
            synology: synology,
            onShowWindow: { [weak self] in self?.showMainWindow() }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep playing in the background — re-opening is via the status item.
        return false
    }

    @MainActor
    private func showMainWindow() {
        if windowController == nil {
            windowController = MainWindowController()
        }
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        // .accessory apps need an explicit activation kick to bring the window
        // to the foreground in front of whatever the user was doing.
        NSApp.activate(ignoringOtherApps: true)
    }
}
