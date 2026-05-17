#if os(iOS)
import SwiftUI

/// Apple-Music-style Now Playing for iOS — a single standard layout (no
/// skins/themes): big artwork, title/artist, scrubber with Lossless pill and
/// elapsed / -remaining, large transport, volume slider, and a bottom row
/// with shuffle / AirPlay / repeat / queue.
struct IOSNowPlayingView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui

    private var p: PlayerState { app.player }

    @State private var scrubbing = false
    @State private var scrubValue: Double = 0
    @State private var volume: Double = 1

    var body: some View {
        Group {
            if let track = p.currentTrack {
                content(track)
            } else {
                Color(.systemBackground)
                    .onAppear { ui.nowPlayingOpen = false }
            }
        }
    }

    private func content(_ track: TrackDTO) -> some View {
        VStack(spacing: 0) {
            grabber

            CoverImage(synology: app.synology, songId: track.id,
                       albumName: track.album, albumArtist: track.albumArtist,
                       cornerRadius: 14)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
                .scaleEffect(p.status == .playing ? 1 : 0.86)
                .animation(.smooth(duration: 0.3), value: p.status == .playing)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)

            scrubber
                .padding(.horizontal, 32)
                .padding(.top, 18)

            transport
                .padding(.top, 22)

            volumeRow
                .padding(.horizontal, 32)
                .padding(.top, 26)

            bottomRow
                .padding(.horizontal, 44)
                .padding(.top, 24)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear { scrubValue = p.position }
    }

    // MARK: pieces

    private var grabber: some View {
        Capsule()
            .fill(.secondary.opacity(0.5))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 18)
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { scrubbing ? scrubValue : p.position },
                    set: { scrubValue = $0 }
                ),
                in: 0...max(p.duration, 0.01),
                onEditingChanged: { editing in
                    scrubbing = editing
                    if !editing { app.engine.seek(seconds: scrubValue) }
                }
            )
            .tint(Theme.accent)

            HStack {
                Text(fmtTime(scrubbing ? scrubValue : p.position))
                Spacer()
                QualityBadge(track: track ?? p.currentTrack)
                Spacer()
                Text("-" + fmtTime(max(0, p.duration - (scrubbing ? scrubValue : p.position))))
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
        }
    }

    private var track: TrackDTO? { p.currentTrack }

    private var transport: some View {
        HStack(spacing: 56) {
            iconButton("backward.fill", 30) {
                Task { try? await app.engine.prev() }
            }
            iconButton(p.status == .playing ? "pause.fill" : "play.fill", 44) {
                app.engine.toggle()
            }
            iconButton("forward.fill", 30) {
                Task { try? await app.engine.next() }
            }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Slider(value: $volume, in: 0...1) { _ in
                app.engine.setVolume(volume)
            }
            .tint(.secondary)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .onChange(of: volume) { app.engine.setVolume(volume) }
    }

    private var bottomRow: some View {
        HStack {
            Button {
                app.engine.setShuffle(!p.shuffle)
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundStyle(p.shuffle ? Theme.accent : .primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            RoutePickerButton()
                .frame(width: 30, height: 30)
            Spacer()
            Button {
                app.engine.setRepeat(nextRepeat(p.repeatMode))
            } label: {
                Image(systemName: p.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 18))
                    .foregroundStyle(p.repeatMode != .off ? Theme.accent : .primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                ui.queueOpen = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private func iconButton(_ symbol: String, _ size: CGFloat,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(.primary)
                .frame(width: size + 22, height: size + 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func nextRepeat(_ m: RepeatMode) -> RepeatMode {
        switch m { case .off: return .all; case .all: return .one; case .one: return .off }
    }
}
#endif
