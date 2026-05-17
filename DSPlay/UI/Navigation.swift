import SwiftUI

/// Sidebar / split-view section selection. Shared by the macOS
/// `MainShellView` and the iOS `iPadSplitShell`.
enum SidebarSelection: Hashable {
    case search, artists, albums, allPlaylists
    case playlist(id: String, name: String)
}

/// The single `Route` → destination mapping, shared by the macOS shell and
/// every iOS navigation stack so the push targets stay identical and there is
/// no duplicated switch.
@MainActor @ViewBuilder
func routeDestination(_ route: Route) -> some View {
    switch route {
    case .artistDetail(let name):
        ArtistDetailView(artist: name)
    case .albumDetail(let artist, let name):
        AlbumDetailView(albumArtist: artist, albumName: name)
    case .playlistDetail(let id):
        PlaylistDetailView(playlistId: id)
    }
}
