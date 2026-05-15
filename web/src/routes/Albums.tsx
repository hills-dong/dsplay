import { For, createResource } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import AlbumCard from "../components/AlbumCard";

export default function AlbumsView() {
  const nav = useNavigate();
  const [data] = createResource(async () => await bridge.call("library.listAlbums", {}));
  return (
    <main class="container" style="padding:32px 32px 48px;">
      <div class="label" style="margin-bottom:24px;">
        Albums{data() ? ` · ${data()!.total}` : "…"}
      </div>
      <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(180px, 1fr)); gap:8px;">
        <For each={data()?.albums}>
          {(album) => <AlbumCard album={album} onClick={() => {
            const artistSeg = album.albumArtist ? encodeURIComponent(album.albumArtist) : "_";
            nav(`/album/${artistSeg}/${encodeURIComponent(album.name)}`);
          }} />}
        </For>
      </div>
    </main>
  );
}
