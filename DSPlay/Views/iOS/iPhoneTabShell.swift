#if os(iOS)
import SwiftUI

private enum iOSTab: Hashable { case search, artists, albums, playlists, settings }

/// iPhone tab-based shell: one `NavigationStack` per section, each attaching
/// the shared `routeDestination` so deep links push identically everywhere.
/// The mini player is an iOS 26 `tabViewBottomAccessory` so it sits *above*
/// the tab bar (Apple Music pattern) instead of overlapping it. Tapping it
/// opens the full-screen Now Playing.
struct iPhoneTabShell: View {
    @Environment(UIState.self) private var ui

    // Selection AND each tab's navigation path are kept in @State on the
    // (stable) shell. Attaching/detaching the bottom accessory on first play
    // rebuilds the TabView; binding these to shell state means the active
    // tab and any pushed detail (e.g. an album) are preserved instead of
    // snapping back to Search / the list.
    @State private var selection: iOSTab = .search
    @State private var searchPath = NavigationPath()
    @State private var artistsPath = NavigationPath()
    @State private var albumsPath = NavigationPath()
    @State private var playlistsPath = NavigationPath()

    @ViewBuilder
    private var tabs: some View {
        TabView(selection: $selection) {
            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                section(SearchView(), "Search", $searchPath)
            }
            Tab("Artists", systemImage: "music.mic", value: .artists) {
                section(ArtistsView(), "Artists", $artistsPath)
            }
            Tab("Albums", systemImage: "square.stack", value: .albums) {
                section(AlbumsView(), "Albums", $albumsPath)
            }
            Tab("Playlists", systemImage: "music.note.list", value: .playlists) {
                section(PlaylistsView(), "Playlists", $playlistsPath)
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                iOSSettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    var body: some View {
        // Attach the accessory UNCONDITIONALLY. Conditionally adding the
        // modifier changes the TabView's view identity, so on first play
        // SwiftUI rebuilt the whole tab tree — causing a visible jump and
        // wiping every tab's @State (e.g. the loaded album list went blank).
        // MiniPlayerBar renders its own idle state when nothing is playing.
        tabs
            .tabViewBottomAccessory { MiniPlayerBar() }
            .fullScreenCover(isPresented: Binding(
                get: { ui.nowPlayingOpen },
                set: { ui.nowPlayingOpen = $0 }
            )) {
                NowPlayingSheet()
            }
    }

    private func section<Content: View>(_ content: Content, _ title: String,
                                        _ path: Binding<NavigationPath>) -> some View {
        NavigationStack(path: path) {
            content
                .navigationDestination(for: Route.self) { routeDestination($0) }
                .navigationTitle(title)
        }
    }
}
#endif
