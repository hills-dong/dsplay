import { createResource, Show } from "solid-js";
import { useParams, useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import TrackList from "../components/TrackList";
import DetailHero from "../components/DetailHero";
import type { Track } from "../types";

export default function AlbumDetailView() {
  const params = useParams<{ artist: string; album: string }>();
  const nav = useNavigate();
  const albumArtist = () => {
    const raw = decodeURIComponent(params.artist);
    return raw === "_" ? "" : raw;
  };
  const albumName = () => decodeURIComponent(params.album);

  const [data] = createResource(
    () => `${albumArtist()}|${albumName()}`,
    async () => await bridge.call("library.songsByAlbum", {
      albumName: albumName(),
      albumArtist: albumArtist(),
    }),
  );

  const pick = async (track: Track) => {
    const songs = data()?.songs ?? [];
    const startIndex = songs.findIndex((t: Track) => t.id === track.id);
    await bridge.call("player.setQueue", {
      trackIds: songs.map((t: Track) => t.id),
      startIndex: Math.max(0, startIndex),
    });
  };

  return (
    <main class="container" style="padding:32px 32px 48px;">
      <DetailHero
        representativeSongId={data()?.songs?.[0]?.id}
        back={{ label: "Albums", onClick: () => nav("/albums") }}
        eyebrow={albumArtist() || "Compilation"}
        title={albumName()}
        meta={data() ? `${data()!.songs.length} songs` : "Loading…"}
      />
      <Show when={data()}>
        <TrackList tracks={data()!.songs} onPick={pick} />
      </Show>
    </main>
  );
}
