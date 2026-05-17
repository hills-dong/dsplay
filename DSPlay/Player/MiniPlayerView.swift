#if os(macOS)
import AppKit
import SwiftUI

struct MiniPlayerView: View {
    @State var state: PlayerState
    let engine: PlaybackEngine
    let synology: SynologyClient
    let onShowWindow: () -> Void
    let onQuit: () -> Void

    private var track: TrackDTO? { state.currentTrack }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                CoverImage(synology: synology, songId: track?.id, albumName: track?.album,
                           albumArtist: track?.albumArtist)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(track?.title ?? "Nothing playing")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    if let a = track?.artist, !a.isEmpty {
                        Text(a).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                    }
                    if let al = track?.album, !al.isEmpty {
                        Text(al).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 24) {
                transportButton("backward.fill", 14) { Task { try? await engine.prev() } }
                transportButton(state.isPlaying ? "pause.fill" : "play.fill", 22) { engine.toggle() }
                transportButton("forward.fill", 14) { Task { try? await engine.next() } }
            }
            .disabled(!state.hasQueue)

            Divider()

            HStack {
                Button("Open Library", action: onShowWindow)
                Spacer()
                Button("Quit", action: onQuit)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12))
        }
        .padding(14)
        .frame(width: 280)
    }

    private func transportButton(_ systemName: String, _ size: CGFloat,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
