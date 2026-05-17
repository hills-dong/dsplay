import SwiftUI

/// Apple-Music-style track rows: index (or a red equalizer glyph for the
/// playing track), title that turns accent-red when current, a trailing •••
/// menu, and a thin inset separator. No full-row fill (that isn't Apple
/// Music) and no hover state on iOS.
struct TrackListView: View {
    let tracks: [TrackDTO]
    let currentTrackId: String?
    /// Apple Music shows the per-track artist only where artists vary
    /// (playlists / search) — never on an album page where it's all the same
    /// album artist. Defaults to on; album detail passes `false`.
    var showArtist: Bool = true
    let onPick: (TrackDTO) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { idx, track in
                TrackRow(index: idx + 1,
                         track: track,
                         isCurrent: currentTrackId == track.id,
                         showArtist: showArtist,
                         onPick: { onPick(track) })
            }
        }
    }
}

private struct TrackRow: View {
    let index: Int
    let track: TrackDTO
    let isCurrent: Bool
    let showArtist: Bool
    let onPick: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: 14) {
                ZStack {
                    if isCurrent {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 16))
                        .foregroundStyle(isCurrent ? Theme.accent : .primary)
                        .lineLimit(1)
                    if showArtist, !track.artist.isEmpty {
                        Text(track.artist)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Menu {
                    Button { onPick() } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .background {
                #if os(macOS)
                if hovering {
                    RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.12))
                }
                #endif
            }
            .overlay(alignment: .bottom) {
                // Explicit horizontal hairline — a bare `Divider()` in an
                // overlay (no stack) renders *vertically*, which stacked down
                // the list looked like one long vertical line.
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: 0.5)
                    .padding(.leading, 38)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .onHover { hovering = $0 }
        #endif
    }
}
