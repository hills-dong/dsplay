#if os(iOS)
import UIKit

/// iOS counterpart of the macOS `AppDelegate`. Owns the long-lived
/// `AppModel` / `UIState` (mirroring how `AppDelegate` owns them on macOS so
/// `RootView` gets the same instances), activates the audio session for
/// background / lock-screen playback, and kicks off silent re-auth.
@MainActor
final class IOSAppDelegate: NSObject, UIApplicationDelegate {
    let appModel = AppModel()
    let uiState = UIState()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AudioSession.activatePlayback()
        Task { @MainActor in await appModel.loadSavedCredentials() }
        return true
    }
}
#endif
