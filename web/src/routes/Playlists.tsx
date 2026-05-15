import { For, createResource } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";
import { friendlyPlaylistName } from "../lib/friendlyPlaylistName";

export default function PlaylistsView() {
  const nav = useNavigate();
  const [data] = createResource(async () => await bridge.call("library.listPlaylists", {} as Record<string, never>));
  return (
    <main class="container" style="padding:32px 32px 48px;">
      <div class="label" style="margin-bottom:24px;">
        Playlists{data() ? ` · ${data()!.playlists.length}` : "…"}
      </div>
      <ol style="list-style:none; padding:0; margin:0;">
        <For each={data()?.playlists}>
          {(pl) => (
            <li
              onClick={() => nav(`/playlist/${encodeURIComponent(pl.id)}`)}
              style="padding:14px 0; border-bottom:1px solid rgba(0,0,0,0.08); cursor:pointer; font-family:var(--font-serif); font-size:18px;"
            >
              {friendlyPlaylistName(pl.name)}
              <span class="label" style="font-size:10px; margin-left:8px; color:var(--mute);">{pl.type}</span>
            </li>
          )}
        </For>
      </ol>
    </main>
  );
}
