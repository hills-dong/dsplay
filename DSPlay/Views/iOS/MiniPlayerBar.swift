#if os(iOS)
import SwiftUI

/// Compact iOS now-playing strip, designed to live inside the TabView's
/// `tabViewBottomAccessory` (which supplies the glass background and sits
/// above the tab bar). Tap to expand to the full-screen Now Playing;
/// horizontal swipe skips tracks.
struct MiniPlayerBar: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui

    private var p: PlayerState { app.player }

    var body: some View {
        if let track = p.currentTrack {
            playing(track)
        } else {
            // Idle: the accessory is always attached (so first play doesn't
            // rebuild the TabView), so show a calm placeholder rather than an
            // empty glass blob.
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                Text("Not Playing")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
    }

    private func playing(_ track: TrackDTO) -> some View {
        HStack(spacing: 10) {
                CoverImage(synology: app.synology, songId: track.id,
                           albumName: track.album, albumArtist: track.albumArtist,
                           cornerRadius: 6)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)

                Button {
                    app.engine.toggle()
                } label: {
                    Image(systemName: p.status == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    Task { try? await app.engine.next() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { ui.nowPlayingOpen = true }
            .highPriorityGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { v in
                        if v.translation.width < -50 {
                            Task { try? await app.engine.next() }
                        } else if v.translation.width > 50 {
                            Task { try? await app.engine.prev() }
                        } else if v.translation.height < -24 {
                            ui.nowPlayingOpen = true
                        }
                    }
            )
        }
    }
#endif
