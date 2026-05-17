import SwiftUI

/// Apple-Music-style floating transport bar. Rounded material slab with a
/// shadow and side margins; internally responsive via ViewThatFits so it
/// degrades cleanly instead of overflowing when the window narrows.
struct PlayerBarView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui
    let openNowPlaying: () -> Void

    private var p: PlayerState { app.player }

    var body: some View {
        if let track = p.currentTrack {
            ViewThatFits(in: .horizontal) {
                bar(track, full: true)
                bar(track, full: false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(maxWidth: 1000)
            .background(
                Theme.paper.opacity(ui.glassScrim),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.20), radius: 16, y: 6)
            .frame(maxWidth: .infinity)
        }
    }

    private func bar(_ track: TrackDTO, full: Bool) -> some View {
        HStack(spacing: 16) {
            transport(full: full)
            Spacer(minLength: 14)
            nowPlaying(track)
            Spacer(minLength: 14)
            rightControls   // volume + AirPlay + queue — always shown
        }
    }

    // MARK: left transport

    private func transport(full: Bool) -> some View {
        HStack(spacing: 16) {
            if full {
                iconButton("shuffle", size: 13,
                           tint: p.shuffle ? Theme.accent : .primary) {
                    app.engine.setShuffle(!p.shuffle)
                }
            }
            iconButton("backward.fill", size: 15) {
                Task { try? await app.engine.prev() }
            }
            iconButton(p.status == .playing ? "pause.fill" : "play.fill", size: 20) {
                app.engine.toggle()
            }
            iconButton("forward.fill", size: 15) {
                Task { try? await app.engine.next() }
            }
            if full {
                iconButton(p.repeatMode == .one ? "repeat.1" : "repeat", size: 13,
                           tint: p.repeatMode != .off ? Theme.accent : .primary) {
                    app.engine.setRepeat(nextRepeat(p.repeatMode))
                }
            }
        }
        .fixedSize()
    }

    // MARK: center now-playing

    private func nowPlaying(_ track: TrackDTO) -> some View {
        Button(action: openNowPlaying) {
            HStack(spacing: 10) {
                CoverImage(synology: app.synology, songId: track.id,
                           albumName: track.album, albumArtist: track.albumArtist,
                           cornerRadius: 4)
                    .frame(width: 38, height: 38)
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        QualityBadge(compact: true, track: track)
                    }
                    Text("\(track.artist) — \(track.album)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    PlayerScrubber()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(width: 420)
            .background(Color.gray.opacity(0.10), in: .rect(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: right controls

    private var rightControls: some View {
        HStack(spacing: 16) {
            VolumeButton()
            RoutePickerButton()
                .frame(width: 24, height: 24)
            iconButton("list.bullet", size: 14,
                       tint: ui.queueOpen ? Theme.accent : .primary) {
                ui.queueOpen.toggle()
            }
        }
        .fixedSize()
    }

    // MARK: helpers

    private func iconButton(_ symbol: String, size: CGFloat,
                            tint: Color = .primary,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func nextRepeat(_ m: RepeatMode) -> RepeatMode {
        switch m { case .off: return .all; case .all: return .one; case .one: return .off }
    }
}

/// Thin scrubber + time, isolated so the 4×/sec position tick only
/// invalidates this small view.
private struct PlayerScrubber: View {
    @Environment(AppModel.self) private var app
    private var p: PlayerState { app.player }

    var body: some View {
        HStack(spacing: 6) {
            Text(fmtTime(p.position))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
            GeometryReader { geo in
                let prog = p.duration > 0 ? p.position / p.duration : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary).frame(height: 3)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(0, geo.size.width * prog), height: 3)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                    let r = min(1, max(0, v.location.x / geo.size.width))
                    app.engine.seek(seconds: r * p.duration)
                })
            }
            .frame(height: 10)
            Text(fmtTime(p.duration))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

/// Volume as a single icon button; tap reveals a slider popover. Always
/// visible (sits with the AirPlay button), never collapsed by ViewThatFits.
private struct VolumeButton: View {
    @Environment(AppModel.self) private var app
    @State private var value: Double = 1
    @State private var open = false

    private var symbol: String {
        if value <= 0.001 { return "speaker.slash.fill" }
        if value < 0.34 { return "speaker.wave.1.fill" }
        if value < 0.67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    var body: some View {
        Button { open.toggle() } label: {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill").font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Slider(value: $value, in: 0...1) { _ in
                    app.engine.setVolume(value)
                }
                .tint(Theme.accent)
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 200)
            .padding(14)
        }
        .onChange(of: value) { app.engine.setVolume(value) }
    }
}
