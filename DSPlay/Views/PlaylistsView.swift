import SwiftUI

struct PlaylistsView: View {
    @Environment(AppModel.self) private var app
    @State private var playlists: [PlaylistDTO]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelText("Playlists" + (playlists.map { " · \($0.count)" } ?? "…"))
                    .padding(.bottom, 24)
                ForEach(playlists ?? []) { pl in
                    NavigationLink(value: Route.playlistDetail(id: pl.id)) {
                        HStack(spacing: 8) {
                            Text(friendlyPlaylistName(pl.name))
                                .font(Theme.serif(18))
                                .foregroundStyle(Theme.ink)
                            LabelText(pl.type, size: 10)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color.black.opacity(0.08))
                }
            }
            .frame(maxWidth: Theme.maxW, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.padX)
            .padding(.vertical, 32)
        }
        .scrollContentBackground(.hidden)
        .thinScrollbars()
        .task {
            if playlists == nil { playlists = try? await app.synology.listPlaylists() }
        }
    }
}
