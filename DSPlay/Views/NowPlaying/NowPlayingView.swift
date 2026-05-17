#if os(macOS)
import SwiftUI

struct NowPlayingView: View {
    @Environment(AppModel.self) private var app
    @Environment(UIState.self) private var ui
    @State private var cover: PlatformImage?

    private var p: PlayerState { app.player }

    var body: some View {
        Group {
            if let track = p.currentTrack {
                let ctx = SkinContext(
                    track: track,
                    isPlaying: p.status == .playing,
                    position: p.position,
                    duration: p.duration,
                    cover: cover,
                    onPlayPause: { app.engine.toggle() },
                    onSeek: { app.engine.seek(seconds: $0) },
                    onNext: { Task { try? await app.engine.next() } },
                    onPrev: { Task { try? await app.engine.prev() } },
                    onClose: { ui.nowPlayingOpen = false }
                )
                skinView(ctx)
            } else {
                Color.clear.onAppear { ui.nowPlayingOpen = false }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        // Click anywhere on the backdrop to dismiss. Buttons / seek bar are
        // their own gestures and take precedence, so controls still work.
        .onTapGesture(perform: close)
        .overlay(alignment: .topLeading) {
            Button(action: close) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    #if os(iOS)
                    .background(.ultraThinMaterial, in: .circle)
                    #endif
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #if os(iOS)
            // Clear the status bar / Dynamic Island and stay tappable above
            // the full-bleed skin artwork.
            .padding(.top, 54)
            .padding(.leading, 16)
            #else
            .padding(.top, 28)
            .padding(.leading, 28)
            #endif
            .zIndex(100)
        }
        #if os(iOS)
        // The Terminal/Winamp/Vinyl skins are scaled-to-fit on iPhone, which
        // shrinks their in-art controls to untappable size. Overlay full-size
        // native transport + skin switcher so they stay usable. Editorial is
        // natively responsive and keeps its own controls.
        .overlay(alignment: .bottom) {
            if ui.skin != .editorial, p.currentTrack != nil {
                noveltyTransport
            }
        }
        .overlay(alignment: .topTrailing) {
            if ui.skin != .editorial {
                SkinSwitcherView()
                    .padding(.top, 54)
                    .padding(.trailing, 16)
                    .zIndex(100)
            }
        }
        #endif
        // Esc to close. `.onExitCommand` works without `.focusable()`, which
        // was intercepting pointer events and eating the Back button's tap.
        // macOS-only: on iOS the hidden focusable button would steal touches
        // and iOS uses swipe-down-to-dismiss instead.
        #if os(macOS)
        .background {
            Button("", action: close)
                .keyboardShortcut(.cancelAction)
                .hidden()
        }
        .onExitCommand(perform: close)
        #endif
        .task(id: p.currentTrack?.id) { await loadCover() }
    }

    private func close() {
        withAnimation(.smooth) { ui.nowPlayingOpen = false }
    }

    #if os(iOS)
    private var noveltyTransport: some View {
        HStack(spacing: 36) {
            transportButton("backward.fill", 22) {
                Task { try? await app.engine.prev() }
            }
            transportButton(p.status == .playing ? "pause.fill" : "play.fill", 30) {
                app.engine.toggle()
            }
            transportButton("forward.fill", 22) {
                Task { try? await app.engine.next() }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: .capsule)
        .padding(.bottom, 40)
        .zIndex(100)
    }

    private func transportButton(_ symbol: String, _ size: CGFloat,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(.primary)
                .frame(width: size + 18, height: size + 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    #endif

    @ViewBuilder
    private func skinView(_ ctx: SkinContext) -> some View {
        switch ui.skin {
        case .editorial: EditorialSkin(ctx: ctx)          // natively responsive
        case .terminal:  SkinFit { TerminalSkin(ctx: ctx) }
        case .winamp:    SkinFit { WinampSkin(ctx: ctx) }
        case .vinyl:     SkinFit { VinylSkin(ctx: ctx) }
        }
    }

    private func loadCover() async {
        cover = nil
        guard let track = p.currentTrack else { return }
        let albumKey = "\(track.albumArtist ?? "")|\(track.album)"
        var repId = track.id
        if !track.album.isEmpty {
            if let cached = CoverCache.shared.repId(forAlbum: albumKey) {
                repId = cached
            } else if let songs = try? await app.synology.songsByAlbum(
                albumName: track.album, albumArtist: track.albumArtist ?? ""),
                      let first = songs.first {
                repId = first.id
                CoverCache.shared.setRepId(repId, forAlbum: albumKey)
            }
        }
        if let cached = CoverCache.shared.image(for: repId) { cover = cached; return }
        guard let url = await app.synology.coverURL(songId: repId),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let img = PlatformImage(data: data) else { return }
        guard p.currentTrack?.id == track.id else { return }
        CoverCache.shared.store(img, for: repId)
        cover = img
    }
}
#endif
