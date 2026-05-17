import SwiftUI

@main
struct DSPlayApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No auto-managed window — AppDelegate creates the NSWindow manually so
        // the menu-bar-resident (.accessory) lifecycle and the vibrant
        // NSVisualEffectView host stay under AppKit control.
        Settings { EmptyView() }
    }
#else
    @UIApplicationDelegateAdaptor(IOSAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.appModel)
                .environment(appDelegate.uiState)
                .preferredColorScheme(appDelegate.uiState.appearance.colorScheme)
        }
    }
#endif
}
