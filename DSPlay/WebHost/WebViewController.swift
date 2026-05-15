import AppKit
import WebKit

@MainActor
final class WebViewController: NSViewController {
    let router: BridgeRouter
    let bridge: BridgeServer
    let events: BridgeEvents
    let synology: SynologyClient
    let playback: PlaybackEngine
    let remote: RemoteCommands

    private var trackCache: [String: TrackDTO] = [:]

    private(set) var webView: WKWebView!
    private var schemeHandler: WebResourceSchemeHandler?
    private var coverHandler: CoverSchemeHandler?

    init() {
        self.router = BridgeRouter()
        self.bridge = BridgeServer(router: router)
        self.events = BridgeEvents(server: bridge)
        self.synology = SynologyClient()
        self.playback = PlaybackEngine(events: events, synology: synology)
        self.remote = RemoteCommands(engine: playback, events: events)
        super.init(nibName: nil, bundle: nil)
        self.synology.savedCredentialsProvider = { try? KeychainService.load() }
        registerHandlers()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let config = WKWebViewConfiguration()
        bridge.attach(to: config)
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Register the custom-scheme handler that serves WebDist via dsplay://app/...
        if let webDistRoot = resolveWebDistDirectory() {
            let handler = WebResourceSchemeHandler(rootDirectory: webDistRoot)
            config.setURLSchemeHandler(handler, forURLScheme: WebResourceSchemeHandler.scheme)
            self.schemeHandler = handler
            NSLog("[DSPlay] scheme handler root = \(webDistRoot.path)")
        } else {
            NSLog("[DSPlay] FATAL: could not resolve WebDist directory")
        }

        let coverHandler = CoverSchemeHandler(synology: synology)
        config.setURLSchemeHandler(coverHandler, forURLScheme: CoverSchemeHandler.scheme)
        self.coverHandler = coverHandler

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        wv.allowsBackForwardNavigationGestures = false
        if #available(macOS 13.3, *) {
            wv.isInspectable = true
        }
        wv.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(wv)
        NSLayoutConstraint.activate([
            wv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            wv.topAnchor.constraint(equalTo: container.topAnchor),
            wv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        self.webView = wv
        bridge.webView = wv
        self.view = container

        loadBundle()
    }

    private func loadBundle() {
        // Optional dev hook: DSPLAY_INITIAL_ROUTE=/albums lets us drive the
        // SPA to a specific route from outside (used for headless screenshot
        // walkthroughs). The scheme handler does SPA fallback for unknown paths.
        let initialPath = ProcessInfo.processInfo.environment["DSPLAY_INITIAL_ROUTE"] ?? "/"
        let normalised = initialPath.hasPrefix("/") ? initialPath : "/" + initialPath
        guard let entryURL = URL(string: "\(WebResourceSchemeHandler.scheme)://\(WebResourceSchemeHandler.host)\(normalised)") else {
            NSLog("[DSPlay] FATAL: failed to construct entry URL for path \(initialPath)")
            return
        }
        NSLog("[DSPlay] loading \(entryURL.absoluteString)")
        webView.load(URLRequest(url: entryURL))
    }

    /// Locate the WebDist directory, regardless of whether we're running from a
    /// swift-bundler-produced .app or from `swift run` / tests using the SwiftPM
    /// intermediate `Bundle.module`.
    private func resolveWebDistDirectory() -> URL? {
        // 1. swift-bundler layout: Bundle.main/Contents/Resources/DSPlay_DSPlay.bundle/Contents/Resources/WebDist
        if let nested = Bundle.main
            .url(forResource: "DSPlay_DSPlay", withExtension: "bundle")
            .flatMap({ Bundle(url: $0) }),
           let webDist = nested.resourceURL?.appendingPathComponent("WebDist"),
           FileManager.default.fileExists(atPath: webDist.path) {
            return webDist
        }
        // 2. SwiftPM module accessor (works for `swift run` / tests).
        if let moduleResourceURL = Bundle.module.resourceURL?.appendingPathComponent("WebDist"),
           FileManager.default.fileExists(atPath: moduleResourceURL.path) {
            return moduleResourceURL
        }
        // 3. Flat in Bundle.main.
        if let flat = Bundle.main.resourceURL?.appendingPathComponent("WebDist"),
           FileManager.default.fileExists(atPath: flat.path) {
            return flat
        }
        return nil
    }

    private func registerHandlers() {
        // ----- Ping (smoke test) -----
        router.register("ping") { payloadData in
            let p = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] ?? [:]
            let nonce = p["nonce"] as? String ?? "?"
            let resp: [String: Any] = ["nonce": nonce, "echoedAt": Date().timeIntervalSince1970]
            return try JSONSerialization.data(withJSONObject: resp)
        }

        // ----- Auth -----
        router.register("auth.login") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let url: String; let user: String; let password: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            try await self.synology.login(url: p.url, user: p.user, password: p.password)
            try KeychainService.save(StoredCredentials(url: p.url, user: p.user, password: p.password))
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("auth.loadSaved") { [weak self] _ in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            guard let saved = try? KeychainService.load() else {
                return try JSONSerialization.data(withJSONObject: ["autoLoggedIn": false])
            }
            do {
                try await self.synology.login(url: saved.url, user: saved.user, password: saved.password)
                return try JSONSerialization.data(withJSONObject: [
                    "autoLoggedIn": true, "url": saved.url, "user": saved.user
                ])
            } catch {
                return try JSONSerialization.data(withJSONObject: ["autoLoggedIn": false])
            }
        }

        router.register("auth.logout") { [weak self] _ in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            await self.synology.logout()
            try KeychainService.clear()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        // ----- Library -----
        router.register("library.search") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let query: String; let limit: Int? }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let tracks = try await self.synology.search(query: p.query, limit: p.limit ?? 50)
            await MainActor.run {
                for t in tracks { self.trackCache[t.id] = t }
            }
            let songs = try tracks.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
            return try JSONSerialization.data(withJSONObject: ["songs": songs, "total": tracks.count])
        }

        router.register("library.listArtists") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let limit: Int?; let offset: Int? }
            let p = (try? JSONDecoder().decode(In.self, from: payloadData)) ?? In(limit: nil, offset: nil)
            let artists = try await self.synology.listArtists(limit: p.limit ?? 200, offset: p.offset ?? 0)
            let payload: [String: Any] = [
                "artists": try artists.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) },
                "total": artists.count
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.listAlbums") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let limit: Int?; let offset: Int? }
            let p = (try? JSONDecoder().decode(In.self, from: payloadData)) ?? In(limit: nil, offset: nil)
            let (albums, total) = try await self.synology.listAlbums(limit: p.limit ?? 200, offset: p.offset ?? 0)
            let payload: [String: Any] = [
                "albums": try albums.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) },
                "total": total
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.listPlaylists") { [weak self] _ in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            let pls = try await self.synology.listPlaylists()
            let payload: [String: Any] = [
                "playlists": try pls.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.songsByAlbum") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let albumName: String; let albumArtist: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let songs = try await self.synology.songsByAlbum(albumName: p.albumName, albumArtist: p.albumArtist)
            await MainActor.run { for t in songs { self.trackCache[t.id] = t } }
            let payload: [String: Any] = [
                "songs": try songs.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.songsByArtist") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let artist: String; let limit: Int?; let offset: Int? }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let (songs, total) = try await self.synology.songsByArtist(artist: p.artist, limit: p.limit ?? 500, offset: p.offset ?? 0)
            await MainActor.run { for t in songs { self.trackCache[t.id] = t } }
            let payload: [String: Any] = [
                "songs": try songs.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) },
                "total": total
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.playlistTracks") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let playlistId: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let songs = try await self.synology.playlistTracks(playlistId: p.playlistId)
            await MainActor.run { for t in songs { self.trackCache[t.id] = t } }
            let payload: [String: Any] = [
                "songs": try songs.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
            ]
            return try JSONSerialization.data(withJSONObject: payload)
        }

        router.register("library.coverUrl") { payloadData in
            struct In: Decodable { let songId: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let url = CoverSchemeHandler.url(forSongId: p.songId).absoluteString
            return try JSONSerialization.data(withJSONObject: ["url": url])
        }

        // ----- Player -----
        // M1 single-track entry point: load + play just one track.
        router.register("player.load") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let trackId: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let cached = await MainActor.run { self.trackCache[p.trackId] }
            guard let track = cached else {
                throw BridgeHandlerError(kind: "Unknown", message: "Unknown trackId; search the library first")
            }
            try await self.playback.setQueue(tracks: [track], startIndex: 0)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        // M2: queue-based entry — replace queue with these tracks and start at startIndex.
        router.register("player.setQueue") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let trackIds: [String]; let startIndex: Int }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let tracks: [TrackDTO] = await MainActor.run { p.trackIds.compactMap { self.trackCache[$0] } }
            guard !tracks.isEmpty else {
                throw BridgeHandlerError(kind: "Unknown", message: "No known tracks; search the library first")
            }
            try await self.playback.setQueue(tracks: tracks, startIndex: p.startIndex)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.queueAdd") { [weak self] payloadData in
            guard let self else { throw BridgeHandlerError(kind: "Unknown", message: "deallocated") }
            struct In: Decodable { let trackIds: [String] }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let tracks: [TrackDTO] = await MainActor.run { p.trackIds.compactMap { self.trackCache[$0] } }
            try await self.playback.queueAdd(tracks: tracks)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.queueRemove") { [weak self] payloadData in
            struct In: Decodable { let index: Int }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            try await self?.playback.queueRemove(at: p.index)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.queueClear") { [weak self] _ in
            await self?.playback.queueClear()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.queueReorder") { [weak self] payloadData in
            struct In: Decodable { let from: Int; let to: Int }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            await self?.playback.queueReorder(from: p.from, to: p.to)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.next") { [weak self] _ in
            try await self?.playback.next()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.prev") { [weak self] _ in
            try await self?.playback.prev()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.setShuffle") { [weak self] payloadData in
            struct In: Decodable { let value: Bool }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            await self?.playback.setShuffle(p.value)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.setRepeat") { [weak self] payloadData in
            struct In: Decodable { let mode: String }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            let mode = RepeatMode(rawValue: p.mode) ?? .off
            await self?.playback.setRepeat(mode)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.play") { [weak self] _ in
            await self?.playback.play()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }
        router.register("player.pause") { [weak self] _ in
            await self?.playback.pause()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }
        router.register("player.toggle") { [weak self] _ in
            await self?.playback.toggle()
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.seek") { [weak self] payloadData in
            struct In: Decodable { let seconds: Double }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            await self?.playback.seek(seconds: p.seconds)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }

        router.register("player.setVolume") { [weak self] payloadData in
            struct In: Decodable { let value: Double }
            let p = try JSONDecoder().decode(In.self, from: payloadData)
            await self?.playback.setVolume(p.value)
            return try JSONSerialization.data(withJSONObject: ["ok": true])
        }
    }
}
