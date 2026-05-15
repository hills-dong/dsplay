import { createSignal } from "solid-js";
import TrackList from "../components/TrackList";
import { bridge } from "../bridge";
import type { Track } from "../types";

export default function SearchView() {
  const [query, setQuery] = createSignal("");
  const [results, setResults] = createSignal<Track[] | null>(null);
  const [busy, setBusy] = createSignal(false);
  const [error, setError] = createSignal<string | null>(null);

  const submit = async (e: Event) => {
    e.preventDefault();
    if (!query().trim()) return;
    setBusy(true); setError(null);
    try {
      const r = await bridge.call("library.search", { query: query().trim() });
      setResults(r.songs);
    } catch (err: any) {
      setError(err?.message ?? String(err));
    } finally {
      setBusy(false);
    }
  };

  const pick = async (track: Track) => {
    const list = results();
    if (!list) return;
    const startIndex = list.findIndex((t) => t.id === track.id);
    try {
      await bridge.call("player.setQueue", {
        trackIds: list.map((t) => t.id),
        startIndex: Math.max(0, startIndex),
      });
    } catch (err) {
      console.error("play failed", err);
    }
  };

  return (
    <main class="container" style="padding:32px 32px 48px;">
      <div class="label" style="margin-bottom:8px;">Search</div>
      <form onsubmit={submit}>
        <input
          type="search"
          value={query()}
          onInput={(e) => setQuery(e.currentTarget.value)}
          placeholder="Type a song, artist, or album…"
          autofocus
          style="width:100%; border-bottom:1px solid var(--ink); padding:12px 0; font-family:var(--font-serif); font-size:28px; font-style:italic;"
        />
      </form>

      {busy() && <p class="label" style="margin-top:32px;">Searching…</p>}
      {error() && <p style="color:var(--accent); margin-top:16px;">{error()}</p>}
      {results() && (
        <>
          <div class="label" style="margin:40px 0 16px;">{results()!.length} results</div>
          <TrackList tracks={results()!} onPick={pick} />
        </>
      )}
    </main>
  );
}
