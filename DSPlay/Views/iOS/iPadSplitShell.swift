#if os(iOS)
import SwiftUI

/// iPad regular-width shell: a `NavigationSplitView` sidebar of the top-level
/// sections + Settings, with the selected section's content in a detail
/// `NavigationStack`. Shares `routeDestination` with every other shell, and
/// reuses the same mini player / full-screen Now Playing as the phone.
struct iPadSplitShell: View {
    @Environment(UIState.self) private var ui

    @State private var section: NavSection? = .search

    var body: some View {
        NavigationSplitView {
            List(selection: $section) {
                ForEach(NavSection.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
                Section {
                    NavigationLink {
                        iOSSettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("DS Music")
        } detail: {
            NavigationStack {
                content
                    .navigationDestination(for: Route.self) { routeDestination($0) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayerBar()
        }
        .fullScreenCover(isPresented: Binding(
            get: { ui.nowPlayingOpen },
            set: { ui.nowPlayingOpen = $0 }
        )) {
            NowPlayingSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section ?? .search {
        case .search:    SearchView().navigationTitle("Search")
        case .artists:   ArtistsView().navigationTitle("Artists")
        case .albums:    AlbumsView().navigationTitle("Albums")
        case .playlists: PlaylistsView().navigationTitle("Playlists")
        }
    }
}
#endif
