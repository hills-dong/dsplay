import { createResource, Show } from "solid-js";
import { useParams, useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import TrackList from "../components/TrackList";
import DetailHero from "../components/DetailHero";
import type { Track } from "../types";

export default function ArtistDetailView() {
  const params = useParams<{ name: string }>();
  const nav = useNavigate();
  const decoded = () => decodeURIComponent(params.name);
  const [data] = createResource(decoded, async (artist) => await bridge.call("library.songsByArtist", { artist }));

  const pick = async (track: Track) => {
    const songs = data()?.songs ?? [];
    const startIndex = songs.findIndex((t: Track) => t.id === track.id);
    await bridge.call("player.setQueue", { trackIds: songs.map((t: Track) => t.id), startIndex: Math.max(0, startIndex) });
  };

  return (
    <main class="container" style="padding:32px 32px 48px;">
      <DetailHero
        representativeSongId={data()?.songs?.[0]?.id}
        back={{ label: "Artists", onClick: () => nav("/artists") }}
        eyebrow="Artist"
        title={decoded()}
        meta={data() ? `${data()!.songs.length} of ${data()!.total} songs` : "Loading…"}
      />
      <Show when={data()}>
        <TrackList tracks={data()!.songs} onPick={pick} />
      </Show>
    </main>
  );
}
