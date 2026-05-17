import Observation
import Foundation

/// Single composition root. Built once by `AppDelegate`, injected into the
/// main window and the menu-bar popover via SwiftUI `.environment`. Owns the
/// long-lived services so playback survives the window being closed.
@MainActor
@Observable
final class AppModel {
    let synology: SynologyClient
    let player: PlayerState
    let engine: PlaybackEngine
    let remote: RemoteCommands

    // Auth state (ported from web/src/stores/auth.ts).
    var isAuthed: Bool = false
    /// True until the on-launch silent re-auth attempt finishes. Lets the
    /// UI show a splash instead of flashing the login screen then the shell.
    var isRestoring: Bool = true
    var nasURL: String = ""
    var user: String = ""

    init() {
        let synology = SynologyClient()
        let player = PlayerState()
        let engine = PlaybackEngine(state: player, synology: synology)
        self.synology = synology
        self.player = player
        self.engine = engine
        self.remote = RemoteCommands(engine: engine)
        self.synology.savedCredentialsProvider = { try? KeychainService.load() }
    }

    /// Silent re-login from the on-disk credential store. Called on launch.
    /// Returns true if it auto-logged-in.
    @discardableResult
    func loadSavedCredentials() async -> Bool {
        defer { isRestoring = false }
        guard let saved = try? KeychainService.load() else { return false }
        do {
            try await synology.login(url: saved.url, user: saved.user, password: saved.password)
            nasURL = saved.url
            user = saved.user
            isAuthed = true
            return true
        } catch {
            return false
        }
    }

    func login(url: String, user: String, password: String) async throws {
        try await synology.login(url: url, user: user, password: password)
        try KeychainService.save(StoredCredentials(url: url, user: user, password: password))
        self.nasURL = url
        self.user = user
        self.isAuthed = true
    }

    func logout() async {
        await synology.logout()
        try? KeychainService.clear()
        isAuthed = false
        engine.queueClear()
    }
}

/// Map Synology's internal playlist sentinels to human-readable names.
/// Ported from web/src/lib/friendlyPlaylistName.ts.
func friendlyPlaylistName(_ name: String) -> String {
    let known = [
        "__SYNO_AUDIO_SHARED_SONGS__": "Shared Songs",
        "__SYNO_AUDIO_FAVORITES__": "Favorites",
    ]
    if let mapped = known[name] { return mapped }
    if let m = name.range(of: "^_+(.+?)_+$", options: .regularExpression) {
        _ = m
        let inner = name.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return inner
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    return name
}
