// shared/ipc-schema.ts — single source of truth for IPC between Swift and the WebView.

export interface Track {
  id: string;
  title: string;
  artist: string;
  albumArtist?: string;
  album: string;
  duration: number;   // seconds
  path?: string;
}

// ----- Requests (JS → Swift, expect a response) -----

export type PingRequest = { type: "ping"; payload: { nonce: string } };
export type AuthLoginRequest = { type: "auth.login"; payload: { url: string; user: string; password: string } };
export type AuthLoadSavedRequest = { type: "auth.loadSaved"; payload: Record<string, never> };
export type AuthLogoutRequest = { type: "auth.logout"; payload: Record<string, never> };
export type LibrarySearchRequest = { type: "library.search"; payload: { query: string; limit?: number } };
export type LibraryListArtistsRequest = { type: "library.listArtists"; payload: { limit?: number; offset?: number } };
export type LibraryListAlbumsRequest = { type: "library.listAlbums"; payload: { limit?: number; offset?: number } };
export type LibraryListPlaylistsRequest = { type: "library.listPlaylists"; payload: Record<string, never> };
export type LibrarySongsByArtistRequest = { type: "library.songsByArtist"; payload: { artist: string; limit?: number; offset?: number } };
export type LibrarySongsByAlbumRequest = { type: "library.songsByAlbum"; payload: { albumName: string; albumArtist: string } };
export type LibraryPlaylistTracksRequest = { type: "library.playlistTracks"; payload: { playlistId: string } };
export type LibraryCoverUrlRequest = { type: "library.coverUrl"; payload: { songId: string } };
export type PlayerLoadRequest = { type: "player.load"; payload: { trackId: string } };
export type PlayerPlayRequest = { type: "player.play"; payload: Record<string, never> };
export type PlayerPauseRequest = { type: "player.pause"; payload: Record<string, never> };
export type PlayerToggleRequest = { type: "player.toggle"; payload: Record<string, never> };
export type PlayerSeekRequest = { type: "player.seek"; payload: { seconds: number } };
export type PlayerSetVolumeRequest = { type: "player.setVolume"; payload: { value: number } };
export type PlayerSetQueueRequest = { type: "player.setQueue"; payload: { trackIds: string[]; startIndex: number } };
export type PlayerQueueAddRequest = { type: "player.queueAdd"; payload: { trackIds: string[] } };
export type PlayerQueueRemoveRequest = { type: "player.queueRemove"; payload: { index: number } };
export type PlayerQueueClearRequest = { type: "player.queueClear"; payload: Record<string, never> };
export type PlayerQueueReorderRequest = { type: "player.queueReorder"; payload: { from: number; to: number } };
export type PlayerNextRequest = { type: "player.next"; payload: Record<string, never> };
export type PlayerPrevRequest = { type: "player.prev"; payload: Record<string, never> };
export type PlayerSetShuffleRequest = { type: "player.setShuffle"; payload: { value: boolean } };
export type PlayerSetRepeatRequest = { type: "player.setRepeat"; payload: { mode: "off" | "all" | "one" } };

export type IPCRequest =
  | PingRequest
  | AuthLoginRequest
  | AuthLoadSavedRequest
  | AuthLogoutRequest
  | LibrarySearchRequest
  | LibraryListArtistsRequest
  | LibraryListAlbumsRequest
  | LibraryListPlaylistsRequest
  | LibrarySongsByArtistRequest
  | LibrarySongsByAlbumRequest
  | LibraryPlaylistTracksRequest
  | LibraryCoverUrlRequest
  | PlayerLoadRequest
  | PlayerPlayRequest
  | PlayerPauseRequest
  | PlayerToggleRequest
  | PlayerSeekRequest
  | PlayerSetVolumeRequest
  | PlayerSetQueueRequest
  | PlayerQueueAddRequest
  | PlayerQueueRemoveRequest
  | PlayerQueueClearRequest
  | PlayerQueueReorderRequest
  | PlayerNextRequest
  | PlayerPrevRequest
  | PlayerSetShuffleRequest
  | PlayerSetRepeatRequest;

// ----- Responses (Swift → JS, matched by requestId) -----

export type PingResponse = { type: "ping"; payload: { nonce: string; echoedAt: number } };
export type AuthLoginResponse = { type: "auth.login"; payload: { ok: true } };
export type AuthLoadSavedResponse = { type: "auth.loadSaved"; payload: { autoLoggedIn: boolean; user?: string; url?: string } };
export type AuthLogoutResponse = { type: "auth.logout"; payload: { ok: true } };
export type LibrarySearchResponse = { type: "library.search"; payload: { songs: Track[]; total: number } };
export interface Artist { name: string }
export interface Album { name: string; albumArtist: string; year: number }
export interface Playlist { id: string; name: string; type: string }

export type LibraryListArtistsResponse = { type: "library.listArtists"; payload: { artists: Artist[]; total: number } };
export type LibraryListAlbumsResponse = { type: "library.listAlbums"; payload: { albums: Album[]; total: number } };
export type LibraryListPlaylistsResponse = { type: "library.listPlaylists"; payload: { playlists: Playlist[] } };
export type LibrarySongsByArtistResponse = { type: "library.songsByArtist"; payload: { songs: Track[]; total: number } };
export type LibrarySongsByAlbumResponse = { type: "library.songsByAlbum"; payload: { songs: Track[] } };
export type LibraryPlaylistTracksResponse = { type: "library.playlistTracks"; payload: { songs: Track[] } };
export type LibraryCoverUrlResponse = { type: "library.coverUrl"; payload: { url: string } };
export type PlayerVoidResponse =
  | { type: "player.load"; payload: { ok: true } }
  | { type: "player.play"; payload: { ok: true } }
  | { type: "player.pause"; payload: { ok: true } }
  | { type: "player.toggle"; payload: { ok: true } }
  | { type: "player.seek"; payload: { ok: true } }
  | { type: "player.setVolume"; payload: { ok: true } }
  | { type: "player.setQueue"; payload: { ok: true } }
  | { type: "player.queueAdd"; payload: { ok: true } }
  | { type: "player.queueRemove"; payload: { ok: true } }
  | { type: "player.queueClear"; payload: { ok: true } }
  | { type: "player.queueReorder"; payload: { ok: true } }
  | { type: "player.next"; payload: { ok: true } }
  | { type: "player.prev"; payload: { ok: true } }
  | { type: "player.setShuffle"; payload: { ok: true } }
  | { type: "player.setRepeat"; payload: { ok: true } };

export type IPCResponse =
  | PingResponse
  | AuthLoginResponse
  | AuthLoadSavedResponse
  | AuthLogoutResponse
  | LibrarySearchResponse
  | LibraryListArtistsResponse
  | LibraryListAlbumsResponse
  | LibraryListPlaylistsResponse
  | LibrarySongsByArtistResponse
  | LibrarySongsByAlbumResponse
  | LibraryPlaylistTracksResponse
  | LibraryCoverUrlResponse
  | PlayerVoidResponse;

// ----- Events (Swift → JS, push) -----

export type PlayerTimeUpdateEvent = { type: "player.timeUpdate"; payload: { position: number; duration: number } };
export type PlayerStateChangeEvent = { type: "player.stateChange"; payload: { state: "idle" | "loading" | "playing" | "paused" | "error"; track?: Track } };
export type PlayerEndedEvent = { type: "player.ended"; payload: Record<string, never> };
export type PlayerErrorEvent = { type: "player.error"; payload: { message: string } };
export type AuthExpiredEvent = { type: "auth.expired"; payload: Record<string, never> };
export type MediaKeyEvent = { type: "mediaKey"; payload: { key: "toggle" | "next" | "prev" } };
export type QueueUpdateEvent = {
  type: "queue.update";
  payload: {
    queue: Track[];
    index: number;            // -1 = nothing playing
    shuffle: boolean;
    repeat: "off" | "all" | "one";
  };
};

export type IPCEvent =
  | PlayerTimeUpdateEvent
  | PlayerStateChangeEvent
  | PlayerEndedEvent
  | PlayerErrorEvent
  | AuthExpiredEvent
  | MediaKeyEvent
  | QueueUpdateEvent;

// ----- Wire envelope -----

export interface RequestEnvelope { kind: "request"; requestId: string; message: IPCRequest; }
export interface ResponseEnvelope { kind: "response"; requestId: string; ok: true; message: IPCResponse; }
export interface ErrorEnvelope    { kind: "response"; requestId: string; ok: false; error: BridgeError; }
export interface EventEnvelope    { kind: "event"; message: IPCEvent; }

export type BridgeErrorKind =
  | "NotAuthenticated"
  | "SessionExpired"
  | "Network"
  | "Synology"
  | "Keychain"
  | "Unknown";

export interface BridgeError { kind: BridgeErrorKind; message: string; code?: number; }
