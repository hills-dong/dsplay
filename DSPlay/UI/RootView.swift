import SwiftUI

enum NavSection: String, CaseIterable, Identifiable {
    case search = "Search"
    case artists = "Artists"
    case albums = "Albums"
    case playlists = "Playlists"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .search:    return "magnifyingglass"
        case .artists:   return "music.mic"
        case .albums:    return "square.stack"
        case .playlists: return "music.note.list"
        }
    }
}

enum Route: Hashable {
    case artistDetail(name: String)
    case albumDetail(artist: String, name: String)
    case playlistDetail(id: String)
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            if app.isRestoring {
                // Silent re-auth from the keychain is in flight — show a calm
                // branded splash instead of flashing LoginView then the shell.
                Color(Theme.paper).ignoresSafeArea()
                HStack(spacing: 0) {
                    Text("DS MUSIC").font(.system(size: 26, weight: .bold))
                    Text(".").font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
                .opacity(0.9)
            } else if app.isAuthed {
                #if os(macOS)
                // Transparent — the real NSVisualEffectView backing lives in
                // MainWindowController so the behind-window blur can sample the
                // desktop. The content column paints its own solid surface.
                MainShellView()
                #else
                iOSRootShell()
                #endif
            } else {
                LoginView()
            }
        }
        #if os(macOS)
        .frame(minWidth: 860, minHeight: 560)
        #endif
        .tint(Theme.accent)
    }
}
