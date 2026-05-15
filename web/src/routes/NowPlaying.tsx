import { createSignal, createMemo, onCleanup, onMount, Show, Switch, Match } from "solid-js";
import { playerStore } from "../stores/player";
import { uiStore, setNowPlayingOpen } from "../stores/ui";
import { bridge } from "../bridge";
import EditorialNowPlaying from "../components/skins/Editorial";
import TerminalNowPlaying from "../components/skins/Terminal";
import WinampNowPlaying from "../components/skins/Winamp";
import VinylNowPlaying from "../components/skins/Vinyl";
import type { SkinProps } from "../components/skins/types";

export default function NowPlaying() {
  const [coverUrl, setCoverUrl] = createSignal("");

  /// Find the album's representative song id and use its embedded cover.
  /// The album grid (AlbumCard) uses the same logic — if the cover renders
  /// there, it renders here too. If the first song has no embedded image,
  /// the WebView's background-image silently fails and the gray placeholder
  /// shows (same fallback behavior as the grid).
  const fetchCover = async () => {
    const track = playerStore.currentTrack;
    if (!track) { setCoverUrl(""); return; }
    let representativeId = track.id;
    if (track.album) {
      try {
        const res = await bridge.call("library.songsByAlbum", {
          albumName: track.album,
          albumArtist: track.albumArtist ?? "",
        });
        if (res.songs.length > 0) representativeId = res.songs[0].id;
      } catch { /* keep currentTrack.id */ }
    }
    try {
      const c = await bridge.call("library.coverUrl", { songId: representativeId });
      setCoverUrl(c.url);
    } catch {
      setCoverUrl("");
    }
  };

  onMount(fetchCover);

  // Re-fetch when the current track changes.
  let lastTrackId = "";
  const tick = () => {
    const id = playerStore.currentTrack?.id ?? "";
    if (id !== lastTrackId) {
      lastTrackId = id;
      fetchCover();
    }
  };
  const interval = setInterval(tick, 500);
  onCleanup(() => clearInterval(interval));

  // Close on Escape.
  const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") setNowPlayingOpen(false); };
  onMount(() => window.addEventListener("keydown", onKey));
  onCleanup(() => window.removeEventListener("keydown", onKey));

  const props = createMemo<SkinProps | null>(() => {
    const t = playerStore.currentTrack;
    if (!t) return null;
    return {
      track: t,
      isPlaying: playerStore.state === "playing",
      position: playerStore.position,
      duration: playerStore.duration,
      coverUrl: coverUrl(),
      onPlayPause: () => bridge.call("player.toggle", {} as Record<string, never>),
      onSeek: (s) => bridge.call("player.seek", { seconds: s }),
      onNext:  () => bridge.call("player.next", {} as Record<string, never>),
      onPrev:  () => bridge.call("player.prev", {} as Record<string, never>),
      onClose: () => setNowPlayingOpen(false),
    };
  });

  return (
    <Show when={props()}>
      {(p) => (
        <Switch fallback={<EditorialNowPlaying {...p()} />}>
          <Match when={uiStore.skin === "terminal"}><TerminalNowPlaying {...p()} /></Match>
          <Match when={uiStore.skin === "winamp"}><WinampNowPlaying {...p()} /></Match>
          <Match when={uiStore.skin === "vinyl"}><VinylNowPlaying {...p()} /></Match>
          <Match when={uiStore.skin === "editorial"}><EditorialNowPlaying {...p()} /></Match>
        </Switch>
      )}
    </Show>
  );
}
