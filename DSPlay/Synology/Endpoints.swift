import Foundation

enum Endpoints {
    static func login(baseURL: String, user: String, password: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/entry.cgi")
        c?.queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "version", value: "7"),
            URLQueryItem(name: "method", value: "login"),
            URLQueryItem(name: "account", value: user),
            URLQueryItem(name: "passwd", value: password),
            URLQueryItem(name: "format", value: "sid"),
        ]
        return c?.url
    }

    static func logout(baseURL: String, sid: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/entry.cgi")
        c?.queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "version", value: "7"),
            URLQueryItem(name: "method", value: "logout"),
            URLQueryItem(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func search(baseURL: String, sid: String, query: String, limit: Int) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/search.cgi")
        c?.queryItems = [
            URLQueryItem(name: "api", value: "SYNO.AudioStation.Search"),
            URLQueryItem(name: "version", value: "1"),
            URLQueryItem(name: "method", value: "list"),
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "additional", value: "song_tag,song_audio"),
            URLQueryItem(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func stream(baseURL: String, sid: String, songId: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/stream.cgi")
        c?.queryItems = [
            URLQueryItem(name: "api", value: "SYNO.AudioStation.Stream"),
            URLQueryItem(name: "version", value: "2"),
            URLQueryItem(name: "method", value: "stream"),
            URLQueryItem(name: "id", value: songId),
            URLQueryItem(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func listArtists(baseURL: String, sid: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/artist.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Artist"),
            .init(name: "version", value: "4"),
            .init(name: "method", value: "list"),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func listAlbums(baseURL: String, sid: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/album.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Album"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "list"),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
            .init(name: "library", value: "all"),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func listPlaylists(baseURL: String, sid: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/playlist.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Playlist"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "list"),
            .init(name: "library", value: "all"),
            .init(name: "limit", value: "200"),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func songsByAlbumArtist(baseURL: String, sid: String, albumArtist: String, limit: Int = 500) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/song.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Song"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "list"),
            .init(name: "album_artist", value: albumArtist),
            .init(name: "additional", value: "song_tag,song_audio"),
            .init(name: "limit", value: String(limit)),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    /// Full song index without any filter. Used as a fallback when no other
    /// server-side filter can locate songs (e.g. compilation albums with
    /// empty album_artist; this NAS doesn't index album names in search.cgi).
    static func listAllSongs(baseURL: String, sid: String, limit: Int = 2000) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/song.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Song"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "list"),
            .init(name: "additional", value: "song_tag,song_audio"),
            .init(name: "limit", value: String(limit)),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func songsByArtist(baseURL: String, sid: String, artist: String, limit: Int, offset: Int) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/song.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Song"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "list"),
            .init(name: "artist", value: artist),
            .init(name: "additional", value: "song_tag,song_audio"),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func playlistInfo(baseURL: String, sid: String, playlistId: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/playlist.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Playlist"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "getinfo"),
            .init(name: "id", value: playlistId),
            .init(name: "additional", value: "songs,songs_song_tag,songs_song_audio"),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }

    static func coverForSong(baseURL: String, sid: String, songId: String) -> URL? {
        var c = URLComponents(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/webapi/AudioStation/cover.cgi")
        c?.queryItems = [
            .init(name: "api", value: "SYNO.AudioStation.Cover"),
            .init(name: "version", value: "3"),
            .init(name: "method", value: "getsongcover"),
            .init(name: "id", value: songId),
            .init(name: "_sid", value: sid),
        ]
        return c?.url
    }
}
