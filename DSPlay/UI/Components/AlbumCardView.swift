import SwiftUI

/// Plain (non-Button) card so it can sit inside a NavigationLink without the
/// inner button swallowing the tap.
struct AlbumCardView: View {
    let synology: SynologyClient
    let album: AlbumDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverImage(synology: synology,
                       songId: album.albumArtist.isEmpty ? nil : album.id,
                       albumName: album.name,
                       albumArtist: album.albumArtist,
                       cornerRadius: 10)
                .aspectRatio(1, contentMode: .fit)
            Text(album.name)
                .font(Theme.serif(14))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(album.albumArtist + (album.year != 0 ? " · \(album.year)" : ""))
                .font(Theme.serif(12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .contentShape(Rectangle())
    }
}
