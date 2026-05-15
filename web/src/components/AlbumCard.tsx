import { createResource, Show } from "solid-js";
import type { Album, Track } from "../types";
import { bridge } from "../bridge";

export default function AlbumCard(props: { album: Album; onClick: () => void }) {
  // Fetch one song from this album to obtain a cover URL.
  const [coverUrl] = createResource(
    () => `${props.album.albumArtist}|${props.album.name}`,
    async () => {
      if (!props.album.albumArtist) return null;
      try {
        const res = await bridge.call("library.songsByAlbum", {
          albumName: props.album.name,
          albumArtist: props.album.albumArtist,
        });
        if (!res.songs.length) return null;
        const first: Track = res.songs[0];
        const c = await bridge.call("library.coverUrl", { songId: first.id });
        return c.url;
      } catch { return null; }
    },
  );

  return (
    <div onClick={props.onClick}
      style="display:flex; flex-direction:column; gap:6px; padding:8px; cursor:pointer;"
    >
      <Show
        when={coverUrl()}
        fallback={<div style="aspect-ratio:1/1; background:var(--cover-bg, #ececea); border:1px solid rgba(0,0,0,0.06);"></div>}
      >
        {(url) => (
          <div style={`
            aspect-ratio:1/1;
            background-image:url("${url()}");
            background-size:cover;
            background-position:center;
            background-color:var(--cover-bg, #ececea);
            border:1px solid rgba(0,0,0,0.06);
          `}></div>
        )}
      </Show>
      <div class="serif" style="font-size:14px; line-height:1.3; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">{props.album.name}</div>
      <div class="serif" style="font-size:12px; color:var(--mute); overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
        {props.album.albumArtist}{props.album.year ? ` · ${props.album.year}` : ""}
      </div>
    </div>
  );
}
