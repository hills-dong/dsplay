import { createResource, Show } from "solid-js";
import type { JSX } from "solid-js";
import { bridge } from "../bridge";

/**
 * Common hero block for AlbumDetail / PlaylistDetail / ArtistDetail.
 * Renders a square cover thumbnail (using the first song's getsongcover as
 * representative art) plus title/subtitle/meta on the right.
 */
export default function DetailHero(props: {
  representativeSongId?: string;   // first song in the collection, used to fetch cover
  eyebrow?: string;                // small caps label (e.g. "ALBUM" or artist name)
  title: JSX.Element;              // big italic serif title
  subtitle?: JSX.Element;          // small grey line beneath title
  meta?: JSX.Element;              // bottom small caps line (e.g. "12 songs")
  back?: { label: string; onClick: () => void };
}) {
  const [coverUrl] = createResource(
    () => props.representativeSongId ?? null,
    async (songId) => {
      try {
        const r = await bridge.call("library.coverUrl", { songId });
        return r.url;
      } catch { return null; }
    },
  );

  return (
    <header style="display:grid; grid-template-columns:220px 1fr; column-gap:32px; margin-bottom:32px; align-items:end;">
      <Show
        when={coverUrl()}
        fallback={
          <div style="aspect-ratio:1/1; width:100%; background:var(--cover-bg, #ececea); border:1px solid rgba(0,0,0,0.06);"></div>
        }
      >
        {(url) => (
          <div style={`
            aspect-ratio:1/1; width:100%;
            background-image:url("${url()}");
            background-size:cover;
            background-position:center;
            background-color:var(--cover-bg, #ececea);
            border:1px solid rgba(0,0,0,0.06);
            box-shadow:0 6px 22px rgba(0,0,0,0.12);
          `}></div>
        )}
      </Show>

      <div>
        <Show when={props.back}>
          {(b) => (
            <button class="label" onClick={b().onClick}
              style="font-size:11px; text-decoration:underline; margin-bottom:14px;"
            >← {b().label}</button>
          )}
        </Show>
        <Show when={props.eyebrow}>
          <div class="label" style="margin-bottom:6px;">{props.eyebrow}</div>
        </Show>
        <h1 style="font-family:var(--font-serif); font-size:42px; font-weight:500; font-style:italic; margin:0 0 8px; line-height:1.1;">
          {props.title}
        </h1>
        <Show when={props.subtitle}>
          <div class="serif" style="font-size:16px; color:var(--mute); margin-bottom:12px;">
            {props.subtitle}
          </div>
        </Show>
        <Show when={props.meta}>
          <div class="label" style="margin-top:6px;">{props.meta}</div>
        </Show>
      </div>
    </header>
  );
}
