import Foundation

final class SynologyClient {
    let session: URLSession
    let authStore: AuthStore
    var savedCredentialsProvider: (@Sendable () async -> StoredCredentials?)?

    init(session: URLSession = .shared, authStore: AuthStore = AuthStore()) {
        self.session = session
        self.authStore = authStore
    }

    func login(url: String, user: String, password: String) async throws {
        guard let endpoint = Endpoints.login(baseURL: url, user: user, password: password) else {
            throw BridgeHandlerError(kind: "Network", message: "Invalid URL: \(url)")
        }
        let env: SynoResponse<LoginData> = try await getJSON(endpoint)
        guard env.success, let data = env.data else {
            throw BridgeHandlerError(kind: "Synology",
                              message: "Login failed (code \(env.error?.code ?? -1))",
                              code: env.error?.code)
        }
        await authStore.set(url: url, user: user, sid: data.sid)
    }

    func logout() async {
        let url = await authStore.url
        let sid = await authStore.sid
        if !sid.isEmpty, let endpoint = Endpoints.logout(baseURL: url, sid: sid) {
            _ = try? await session.data(from: endpoint)
        }
        await authStore.clear()
    }

    func search(query: String, limit: Int = 50) async throws -> [TrackDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // 1) Fast path: Synology server-side search.
        if let env: SynoResponse<SearchData> = try? await authedJSON({ sid, base in
            guard let url = Endpoints.search(baseURL: base, sid: sid,
                                             query: trimmed, limit: limit) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid search URL")
            }
            return url
        }), env.success, let songs = env.data?.songs, !songs.isEmpty {
            return songs.map(TrackDTO.init)
        }

        // 2) Fallback: server search often only prefix-matches titles and
        //    misses artist/album or substring queries. Pull the full song
        //    index and filter locally (title / artist / album, case- and
        //    diacritic-insensitive).
        let all = try await allSongs(limit: 5000)
        let needle = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                     locale: .current)
        func has(_ s: String) -> Bool {
            s.folding(options: [.caseInsensitive, .diacriticInsensitive],
                      locale: .current).contains(needle)
        }
        return all.filter {
            has($0.title) || has($0.artist) || has($0.album)
                || has($0.albumArtist ?? "")
        }
    }

    /// Full song index as TrackDTOs (used by search fallback).
    private func allSongs(limit: Int = 5000) async throws -> [TrackDTO] {
        let env: SynoResponse<SearchData> = try await authedJSON { sid, base in
            guard let url = Endpoints.listAllSongs(baseURL: base, sid: sid, limit: limit) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid listAllSongs URL")
            }
            return url
        }
        guard env.success else {
            throw BridgeHandlerError(kind: "Synology",
                              message: "Song list failed (code \(env.error?.code ?? -1))",
                              code: env.error?.code)
        }
        return (env.data?.songs ?? []).map(TrackDTO.init)
    }

    func streamURL(songId: String) async -> URL? {
        let base = await authStore.url
        let sid = await authStore.sid
        return Endpoints.stream(baseURL: base, sid: sid, songId: songId)
    }

    func listArtists(limit: Int = 200, offset: Int = 0) async throws -> [ArtistDTO] {
        let env: SynoResponse<ArtistData> = try await authedJSON { sid, base in
            guard let url = Endpoints.listArtists(baseURL: base, sid: sid, limit: limit, offset: offset) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid artists URL")
            }
            return url
        }
        guard env.success, let data = env.data else {
            throw BridgeHandlerError(kind: "Synology", message: "listArtists failed (code \(env.error?.code ?? -1))", code: env.error?.code)
        }
        return (data.artists ?? []).filter { !$0.name.isEmpty }.map { ArtistDTO(name: $0.name) }
    }

    func listAlbums(limit: Int = 200, offset: Int = 0) async throws -> (albums: [AlbumDTO], total: Int) {
        let env: SynoResponse<AlbumData> = try await authedJSON { sid, base in
            guard let url = Endpoints.listAlbums(baseURL: base, sid: sid, limit: limit, offset: offset) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid albums URL")
            }
            return url
        }
        guard env.success, let data = env.data else {
            throw BridgeHandlerError(kind: "Synology", message: "listAlbums failed (code \(env.error?.code ?? -1))", code: env.error?.code)
        }
        let albums = (data.albums ?? []).map {
            AlbumDTO(
                name: $0.name,
                albumArtist: $0.album_artist ?? $0.display_artist ?? "",
                year: $0.year ?? 0
            )
        }
        return (albums, data.total)
    }

    func listPlaylists() async throws -> [PlaylistDTO] {
        let env: SynoResponse<PlaylistData> = try await authedJSON { sid, base in
            guard let url = Endpoints.listPlaylists(baseURL: base, sid: sid) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid playlists URL")
            }
            return url
        }
        guard env.success, let data = env.data else {
            throw BridgeHandlerError(kind: "Synology", message: "listPlaylists failed (code \(env.error?.code ?? -1))", code: env.error?.code)
        }
        return (data.playlists ?? []).map { PlaylistDTO(id: $0.id, name: $0.name, type: $0.type ?? "normal") }
    }

    func songsByAlbum(albumName: String, albumArtist: String) async throws -> [TrackDTO] {
        let want = albumName.trimmingCharacters(in: .whitespaces)

        // Path A: when album_artist is known, use song.cgi?album_artist=... (server-side,
        // narrows the result before client-side album-name filter).
        if !albumArtist.trimmingCharacters(in: .whitespaces).isEmpty {
            let env: SynoResponse<SearchData> = try await authedJSON { sid, base in
                guard let url = Endpoints.songsByAlbumArtist(baseURL: base, sid: sid, albumArtist: albumArtist) else {
                    throw BridgeHandlerError(kind: "Network", message: "Invalid songsByAlbumArtist URL")
                }
                return url
            }
            guard env.success else {
                throw BridgeHandlerError(kind: "Synology",
                                  message: "songsByAlbum failed (code \(env.error?.code ?? -1))",
                                  code: env.error?.code)
            }
            let matching = (env.data?.songs ?? []).filter {
                ($0.additional?.song_tag?.album?.trimmingCharacters(in: .whitespaces) ?? "") == want
            }
            return matching.map(TrackDTO.init)
        }

        // Path B: no album_artist (compilation albums, soundtracks, etc.).
        // search.cgi doesn't index album names on this NAS, so we fall back to
        // listing the full song library (limit 2000) and filtering client-side
        // by album name. This is one heavy request per album-detail visit but
        // it's the only path that actually finds these tracks.
        let env: SynoResponse<SearchData> = try await authedJSON { sid, base in
            guard let url = Endpoints.listAllSongs(baseURL: base, sid: sid, limit: 2000) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid listAllSongs URL")
            }
            return url
        }
        guard env.success else {
            throw BridgeHandlerError(kind: "Synology",
                              message: "songsByAlbum (full-list fallback) failed (code \(env.error?.code ?? -1))",
                              code: env.error?.code)
        }
        let matching = (env.data?.songs ?? []).filter {
            ($0.additional?.song_tag?.album?.trimmingCharacters(in: .whitespaces) ?? "") == want
        }
        return matching.map(TrackDTO.init)
    }

    func songsByArtist(artist: String, limit: Int = 500, offset: Int = 0) async throws -> (songs: [TrackDTO], total: Int) {
        let env: SynoResponse<SearchData> = try await authedJSON { sid, base in
            guard let url = Endpoints.songsByArtist(baseURL: base, sid: sid, artist: artist, limit: limit, offset: offset) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid songsByArtist URL")
            }
            return url
        }
        // song.cgi returns `total` not `songTotal`. Re-decode if needed.
        // Practically: SearchData expects `songTotal`. We'll handle the divergence by using a dedicated DTO.
        guard env.success else {
            throw BridgeHandlerError(kind: "Synology", message: "songsByArtist failed (code \(env.error?.code ?? -1))", code: env.error?.code)
        }
        let songs = (env.data?.songs ?? []).map(TrackDTO.init)
        return (songs, env.data?.totalCount ?? songs.count)
    }

    func playlistTracks(playlistId: String) async throws -> [TrackDTO] {
        let env: SynoResponse<PlaylistInfoData> = try await authedJSON { sid, base in
            guard let url = Endpoints.playlistInfo(baseURL: base, sid: sid, playlistId: playlistId) else {
                throw BridgeHandlerError(kind: "Network", message: "Invalid playlist info URL")
            }
            return url
        }
        guard env.success, let data = env.data, let first = data.playlists.first else {
            throw BridgeHandlerError(kind: "Synology", message: "playlistTracks failed (code \(env.error?.code ?? -1))", code: env.error?.code)
        }
        return (first.additional?.songs ?? []).map(TrackDTO.init)
    }

    func coverURL(songId: String) async -> URL? {
        let base = await authStore.url
        let sid = await authStore.sid
        return Endpoints.coverForSong(baseURL: base, sid: sid, songId: songId)
    }

    // MARK: helpers

    private func getJSON<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BridgeHandlerError(kind: "Network", message: "HTTP \(http.statusCode) for \(url.path)")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw BridgeHandlerError(kind: "Network", message: "JSON decode failed: \(error)")
        }
    }

    /// Calls the given URL builder with the current SID. If Synology returns
    /// session-expiry codes (105 or 119), attempts a silent re-auth using saved
    /// credentials and retries once.
    private func authedJSON<T: Decodable>(
        _ buildURL: @escaping (_ sid: String, _ base: String) async throws -> URL
    ) async throws -> SynoResponse<T> {
        async let sidPromise = authStore.sid
        async let basePromise = authStore.url
        let sid = await sidPromise
        let base = await basePromise

        if sid.isEmpty {
            throw BridgeHandlerError(kind: "NotAuthenticated", message: "Not signed in")
        }

        let url = try await buildURL(sid, base)
        var env: SynoResponse<T> = try await getJSON(url)

        if !env.success, let code = env.error?.code, code == 105 || code == 119 {
            if let saved = await savedCredentialsProvider?() {
                try await self.login(url: saved.url, user: saved.user, password: saved.password)
                let url2 = try await buildURL(await authStore.sid, await authStore.url)
                env = try await getJSON(url2)
                if !env.success {
                    throw BridgeHandlerError(kind: "SessionExpired",
                                      message: "Re-auth retried but server still rejected (code \(env.error?.code ?? -1))",
                                      code: env.error?.code)
                }
            } else {
                throw BridgeHandlerError(kind: "SessionExpired", message: "Session expired and no saved credentials available")
            }
        }
        return env
    }
}
