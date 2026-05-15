import { createResource, Show } from "solid-js";
import { useParams, useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import TrackList from "../components/TrackList";
import DetailHero from "../components/DetailHero";
import { friendlyPlaylistName } from "../lib/friendlyPlaylistName";
import type { Track } from "../types";

export default function PlaylistDetailView() {
  const params = useParams<{ id: string }>();
  const nav = useNavigate();
  const [data] = createResource(
    () => decodeURIComponent(params.id),
    async (playlistId) => await bridge.call("library.playlistTracks", { playlistId })
  );

  const pick = async (track: Track) => {
    const songs = data()?.songs ?? [];
    const startIndex = songs.findIndex((t: Track) => t.id === track.id);
    await bridge.call("player.setQueue", { trackIds: songs.map((t: Track) => t.id), startIndex: Math.max(0, startIndex) });
  };

  // Playlist IDs look like "playlist_personal_normal/__SYNO_AUDIO_SHARED_SONGS__".
  // Extract the trailing segment and pretty-print it.
  const displayName = () =>
    friendlyPlaylistName(decodeURIComponent(params.id).split("/").pop() ?? "Playlist");

  return (
    <main class="container" style="padding:32px 32px 48px;">
      <DetailHero
        representativeSongId={data()?.songs?.[0]?.id}
        back={{ label: "Playlists", onClick: () => nav("/playlists") }}
        eyebrow="Playlist"
        title={displayName()}
        meta={data() ? `${data()!.songs.length} songs` : "Loading…"}
      />
      <Show when={data()}>
        <TrackList tracks={data()!.songs} onPick={pick} />
      </Show>
    </main>
  );
}
