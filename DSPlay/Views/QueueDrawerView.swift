import SwiftUI

/// Apple-Music-style "Up Next" column: artwork thumbnails, title/artist,
/// the current track highlighted.
struct QueueDrawerView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui

    private var p: PlayerState { app.player }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Up Next").font(.system(size: 17, weight: .bold))
                Spacer()
                Button("Clear") { app.engine.queueClear() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(p.queue.enumerated()), id: \.element.id) { idx, track in
                        QueueRow(track: track,
                                 isCurrent: idx == p.queueIndex,
                                 synology: app.synology,
                                 onTap: {
                                     Task { try? await app.engine.setQueue(
                                         tracks: p.queue, startIndex: idx) }
                                 },
                                 onRemove: {
                                     Task { try? await app.engine.queueRemove(at: idx) }
                                 })
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 90)
            }
            .scrollContentBackground(.hidden)
            .thinScrollbars()
        }
    }
}

private struct QueueRow: View {
    let track: TrackDTO
    let isCurrent: Bool
    let synology: SynologyClient
    let onTap: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    private var removeAlwaysVisible: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        HStack(spacing: 10) {
            CoverImage(synology: synology, songId: track.id,
                       albumName: track.album, albumArtist: track.albumArtist,
                       cornerRadius: 5)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Theme.accent : .primary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            // macOS reveals the remove control on hover; iOS (no hover) keeps
            // it always visible with a larger touch target.
            if hovering || removeAlwaysVisible {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: removeAlwaysVisible ? 12 : 9))
                        .frame(width: removeAlwaysVisible ? 30 : 16,
                               height: removeAlwaysVisible ? 30 : 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            if isCurrent {
                RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.14))
            } else if hovering {
                RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.10))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering = $0 }
    }
}
