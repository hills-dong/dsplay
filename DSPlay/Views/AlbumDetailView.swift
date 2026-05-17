import SwiftUI

struct AlbumDetailView: View {
    @Environment(AppModel.self) private var app
    let albumArtist: String
    let albumName: String

    @State private var songs: [TrackDTO]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                DetailHeroView(
                    synology: app.synology,
                    representativeSongId: songs?.first?.id,
                    eyebrow: albumArtist.isEmpty ? "Compilation" : albumArtist,
                    title: albumName,
                    meta: songs.map { "\($0.count) songs" } ?? "Loading…",
                    onPlay: playAll,
                    onShuffle: shufflePlay
                )
                if let songs {
                    TrackListView(tracks: songs,
                                  currentTrackId: app.player.currentTrack?.id,
                                  showArtist: false,
                                  onPick: pick)
                }
            }
            .frame(maxWidth: Theme.maxW, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.padX)
            .padding(.vertical, 32)
        }
        .scrollContentBackground(.hidden)
        .thinScrollbars()
        .task(id: "\(albumArtist)|\(albumName)") {
            songs = (try? await app.synology.songsByAlbum(
                albumName: albumName, albumArtist: albumArtist)) ?? []
        }
    }

    private func pick(_ track: TrackDTO) {
        guard let list = songs,
              let start = list.firstIndex(where: { $0.id == track.id }) else { return }
        Task { try? await app.engine.setQueue(tracks: list, startIndex: start) }
    }

    private func playAll() {
        guard let songs, !songs.isEmpty else { return }
        app.engine.setShuffle(false)
        Task { try? await app.engine.setQueue(tracks: songs, startIndex: 0) }
    }

    private func shufflePlay() {
        guard let songs, !songs.isEmpty else { return }
        app.engine.setShuffle(true)
        Task { try? await app.engine.setQueue(
            tracks: songs, startIndex: Int.random(in: 0..<songs.count)) }
    }
}
