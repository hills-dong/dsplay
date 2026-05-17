import SwiftUI

/// Process-wide cover cache keyed by the resolved representative song id.
@MainActor
final class CoverCache {
    static let shared = CoverCache()
    private let cache = NSCache<NSString, PlatformImage>()
    /// album-key → representative songId, so the AlbumDetail / NowPlaying
    /// two-step (songsByAlbum → songs[0].id) is only paid once.
    private var repIdByAlbum: [String: String] = [:]

    func image(for key: String) -> PlatformImage? { cache.object(forKey: key as NSString) }
    func store(_ img: PlatformImage, for key: String) { cache.setObject(img, forKey: key as NSString) }
    func repId(forAlbum key: String) -> String? { repIdByAlbum[key] }
    func setRepId(_ id: String, forAlbum key: String) { repIdByAlbum[key] = id }
}

/// Async cover loader replacing the old `dsplaycover://` scheme. Resolves a
/// representative song for an album (the NAS embeds art per-song), fetches via
/// `SynologyClient.coverURL`, and caches. Falls back to a gray placeholder.
struct CoverImage: View {
    let synology: SynologyClient
    let songId: String?
    var albumName: String? = nil
    var albumArtist: String? = nil
    var cornerRadius: CGFloat = 0

    @State private var image: PlatformImage?

    private var albumKey: String? {
        guard let albumName, !albumName.isEmpty else { return nil }
        return "\(albumArtist ?? "")|\(albumName)"
    }

    var body: some View {
        ZStack {
            Theme.coverBG
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .task(id: taskKey) { await load() }
    }

    private var taskKey: String { albumKey ?? songId ?? "" }

    private func load() async {
        image = nil

        // Resolve the representative song id. Prefer the album lookup (so
        // compilation albums with no album-artist — e.g. soundtracks — still
        // get art, matching the detail page); fall back to an explicit
        // songId when there's no album context.
        var repId: String? = nil
        if let albumKey {
            if let cached = CoverCache.shared.repId(forAlbum: albumKey) {
                repId = cached
            } else if let albumName {
                if let songs = try? await synology.songsByAlbum(
                    albumName: albumName, albumArtist: albumArtist ?? ""),
                   let first = songs.first {
                    repId = first.id
                    CoverCache.shared.setRepId(first.id, forAlbum: albumKey)
                }
            }
        }
        if repId == nil { repId = songId }
        guard let repId else { return }

        let cacheKey = repId
        if let cached = CoverCache.shared.image(for: cacheKey) {
            image = cached
            return
        }
        guard let url = await synology.coverURL(songId: repId),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let img = PlatformImage(data: data) else { return }
        // The view may have been recycled to another track during the fetch.
        guard taskKey == (albumKey ?? songId ?? "") else { return }
        CoverCache.shared.store(img, for: cacheKey)
        image = img
    }
}
