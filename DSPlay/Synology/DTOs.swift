import Foundation

struct SynoResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: SynoErrorBody?
}

struct SynoErrorBody: Decodable {
    let code: Int
}

struct LoginData: Decodable {
    let sid: String
}

struct SearchData: Decodable {
    let songTotal: Int?      // search.cgi uses this
    let total: Int?          // song.cgi list uses this
    let songs: [RawSong]?

    var totalCount: Int {
        songTotal ?? total ?? songs?.count ?? 0
    }
}

struct RawSong: Decodable {
    let id: String
    let title: String
    let path: String?
    let additional: Additional?

    struct Additional: Decodable {
        let song_tag: SongTag?
        let song_audio: SongAudio?
    }
    struct SongTag: Decodable {
        let album: String?
        let artist: String?
        let album_artist: String?
    }
    struct SongAudio: Decodable {
        let duration: Double?
    }
}

struct ArtistData: Decodable {
    let total: Int
    let artists: [RawArtist]?
}
struct RawArtist: Decodable {
    let name: String
}

struct AlbumData: Decodable {
    let total: Int
    let albums: [RawAlbum]?
}
struct RawAlbum: Decodable {
    let name: String
    let album_artist: String?
    let display_artist: String?
    let year: Int?
}

struct PlaylistData: Decodable {
    let playlists: [RawPlaylist]?
}
struct RawPlaylist: Decodable {
    let id: String
    let name: String
    let type: String?
}

struct PlaylistInfoData: Decodable {
    let playlists: [PlaylistInfoEntry]
    struct PlaylistInfoEntry: Decodable {
        let id: String
        let additional: PlaylistAdditional?
        struct PlaylistAdditional: Decodable {
            let songs: [RawSong]?
        }
    }
}

struct ArtistDTO: Encodable { let name: String }
struct AlbumDTO: Encodable { let name: String; let albumArtist: String; let year: Int }
struct PlaylistDTO: Encodable { let id: String; let name: String; let type: String }

/// Outgoing shape matching shared/ipc-schema.ts `Track`.
struct TrackDTO: Encodable {
    let id: String
    let title: String
    let artist: String
    let albumArtist: String?
    let album: String
    let duration: Double
    let path: String?

    init(_ raw: RawSong) {
        self.id = raw.id
        self.title = raw.title
        self.artist = raw.additional?.song_tag?.artist ?? "Unknown Artist"
        self.albumArtist = raw.additional?.song_tag?.album_artist
        self.album = raw.additional?.song_tag?.album ?? "Unknown Album"
        self.duration = raw.additional?.song_audio?.duration ?? 0
        self.path = raw.path
    }
}
