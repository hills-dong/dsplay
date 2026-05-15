import { For, createResource } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { bridge } from "../bridge";

export default function ArtistsView() {
  const nav = useNavigate();
  const [data] = createResource(async () => await bridge.call("library.listArtists", {}));
  return (
    <main class="container" style="padding:32px 32px 48px;">
      <div class="label" style="margin-bottom:24px;">
        Artists{data() ? ` · ${data()!.artists.length}` : "…"}
      </div>
      <ol style="list-style:none; padding:0; margin:0;">
        <For each={data()?.artists}>
          {(a) => (
            <li
              onClick={() => nav(`/artist/${encodeURIComponent(a.name)}`)}
              style="padding:12px 0; border-bottom:1px solid rgba(0,0,0,0.08); cursor:pointer; font-family:var(--font-serif); font-size:18px;"
            >{a.name}</li>
          )}
        </For>
      </ol>
    </main>
  );
}
