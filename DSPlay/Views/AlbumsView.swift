import SwiftUI

struct AlbumsView: View {
    @Environment(AppModel.self) private var app
    @State private var albums: [AlbumDTO]?
    @State private var total = 0

    #if os(iOS)
    // Lower minimum so even a 375pt-wide iPhone gets a 2-up grid.
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
    #else
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 8)]
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelText("Albums" + (albums != nil ? " · \(total)" : "…"))
                    .padding(.bottom, 24)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(albums ?? []) { album in
                        NavigationLink(value: Route.albumDetail(
                            artist: album.albumArtist, name: album.name)) {
                            AlbumCardView(synology: app.synology, album: album)
                        }
                        .buttonStyle(.plain)
                    }
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
            if albums == nil {
                let r = try? await app.synology.listAlbums()
                albums = r?.albums ?? []
                total = r?.total ?? 0
            }
        }
    }
}
