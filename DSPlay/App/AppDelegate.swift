#if os(macOS)
import Cocoa
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appModel = AppModel()
    private let uiState = UIState()
    private var windowController: MainWindowController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ScrollerTheming.enableOverlayScrollers()
        uiState.applyAppearance()

        // Menu-bar-resident: the status item is the entry point. Build the
        // window lazily on first "Open Library" so launch is light.
        statusItemController = StatusItemController(
            engine: appModel.engine,
            synology: appModel.synology,
            state: appModel.player,
            onShowWindow: { [weak self] in self?.showMainWindow() }
        )

        // Silent re-auth from the on-disk credential store.
        Task { @MainActor in await appModel.loadSavedCredentials() }

        // Open the main window on launch (the status item stays available
        // for re-opening after the window is closed).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showMainWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep playing in the background — re-opening is via the status item.
        return false
    }

    @MainActor
    private func showMainWindow() {
        if windowController == nil {
            windowController = MainWindowController(appModel: appModel, uiState: uiState)
        }
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        // .accessory apps need an explicit activation kick to bring the window
        // to the foreground in front of whatever the user was doing.
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
