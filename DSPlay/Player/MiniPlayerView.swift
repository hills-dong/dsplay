import AppKit
import SwiftUI

@MainActor
final class MiniPlayerModel: ObservableObject {
    @Published private(set) var title: String = "Nothing playing"
    @Published private(set) var artist: String = ""
    @Published private(set) var album: String = ""
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var hasQueue: Bool = false
    @Published private(set) var cover: NSImage?

    private weak var engine: PlaybackEngine?
    private let synology: SynologyClient
    private var timer: Timer?
    private var lastSongId: String?

    init(engine: PlaybackEngine, synology: SynologyClient) {
        self.engine = engine
        self.synology = synology
    }

    func start() {
        guard timer == nil else { return }
        refresh()
        // No event bus from PlaybackEngine to Swift observers; poll while the
        // popover is open (we pause when it closes).
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlay() {
        engine?.toggle()
        refresh()
    }

    func next() {
        Task { @MainActor in try? await engine?.next() }
    }

    func prev() {
        Task { @MainActor in try? await engine?.prev() }
    }

    private func refresh() {
        let track = engine?.currentTrack
        isPlaying = engine?.isPlaying ?? false
        hasQueue = (engine?.queue.count ?? 0) > 0
        title = track?.title ?? "Nothing playing"
        artist = track?.artist ?? ""
        album = track?.album ?? ""

        if track?.id != lastSongId {
            lastSongId = track?.id
            cover = nil
            if let id = track?.id {
                Task { @MainActor in await loadCover(songId: id) }
            }
        }
    }

    private func loadCover(songId: String) async {
        guard let url = await synology.coverURL(songId: songId) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        // Track may have changed during the fetch — only apply if still current.
        guard songId == lastSongId, let img = NSImage(data: data) else { return }
        cover = img
    }
}

struct MiniPlayerView: View {
    @ObservedObject var model: MiniPlayerModel
    let onShowWindow: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                coverView
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    if !model.artist.isEmpty {
                        Text(model.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    if !model.album.isEmpty {
                        Text(model.album)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 24) {
                transportButton(systemName: "backward.fill", size: 14, action: model.prev)
                transportButton(
                    systemName: model.isPlaying ? "pause.fill" : "play.fill",
                    size: 22,
                    action: model.togglePlay
                )
                transportButton(systemName: "forward.fill", size: 14, action: model.next)
            }
            .disabled(!model.hasQueue)

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

    @ViewBuilder
    private var coverView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
            if let img = model.cover {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func transportButton(systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
