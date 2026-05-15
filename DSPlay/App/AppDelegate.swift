import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: MainWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let wc = MainWindowController()
        wc.showWindow(nil)
        windowController = wc
        NSApp.activate(ignoringOtherApps: true)

        // Status item — needs the playback engine to control playback from the menubar.
        let engine = wc.webViewController.playback
        let events = wc.webViewController.events
        statusItemController = StatusItemController(
            engine: engine,
            events: events,
            onShowWindow: { [weak self] in self?.showMainWindow() }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep playing in the background — re-opening is via Dock icon, status item, or
        // Cmd+N (App menu would route here too if we add one).
        return false
    }

    /// macOS sends this when the user clicks the Dock icon and there are no
    /// visible windows. We reopen the main window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    @MainActor
    private func showMainWindow() {
        if windowController == nil {
            windowController = MainWindowController()
        }
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
