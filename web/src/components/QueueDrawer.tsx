import { For, Show } from "solid-js";
import { playerStore } from "../stores/player";
import { uiStore, setQueueOpen } from "../stores/ui";
import { bridge } from "../bridge";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

export default function QueueDrawer() {
  return (
    <Show when={uiStore.queueOpen}>
      <aside style="
        position:fixed; top:0; right:0; bottom:0; width:380px;
        background:rgba(250,250,247,0.94); backdrop-filter:blur(20px);
        border-left:1px solid var(--ink);
        z-index:90;
        display:flex; flex-direction:column;
      ">
        {/* Fixed header (doesn't scroll with the track list). */}
        <header style="
          flex-shrink:0;
          padding:48px 24px 16px;
          background:inherit;
          border-bottom:1px solid rgba(0,0,0,0.08);
          display:flex; justify-content:space-between; align-items:baseline;
        ">
          <span class="label">Queue · {playerStore.queue.length}</span>
          <div style="display:flex; gap:12px;">
            <button class="label"
              onClick={() => bridge.call("player.queueClear", {} as Record<string, never>)}
              style="font-size:11px; text-decoration:underline; color:var(--mute);"
            >CLEAR</button>
            <button class="label"
              onClick={() => setQueueOpen(false)}
              style="font-size:11px;"
            >✕ CLOSE</button>
          </div>
        </header>

        {/* Scrolling track list. */}
        <div style="flex:1; overflow-y:auto; overscroll-behavior:contain; padding:8px 24px 96px;">
          <ol style="list-style:none; padding:0; margin:0;">
            <For each={playerStore.queue}>
              {(track, i) => {
                const isCurrent = () => i() === playerStore.queueIndex;
                return (
                  <li style={`
                    display:grid; grid-template-columns:auto 1fr auto auto;
                    column-gap:10px; align-items:baseline;
                    padding:10px 0;
                    border-bottom:1px solid rgba(0,0,0,0.06);
                  `}>
                    <span class="mono" style={`color:${isCurrent() ? "var(--accent)" : "var(--mute)"}; font-size:11px;`}>
                      {isCurrent() ? "▸" : String(i() + 1).padStart(2, "0")}
                    </span>
                    <div style="min-width:0;">
                      <div class="serif"
                        style={`font-size:14px; color:${isCurrent() ? "var(--accent)" : "var(--ink)"}; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;`}
                      >{track.title}</div>
                      <div class="serif" style="font-size:11px; color:var(--mute); overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
                        {track.artist}
                      </div>
                    </div>
                    <span class="mono" style="font-size:11px; color:var(--mute);">{fmt(track.duration)}</span>
                    <button class="label"
                      title="Remove"
                      onClick={() => bridge.call("player.queueRemove", { index: i() })}
                      style="font-size:10px; opacity:0.5;"
                    >✕</button>
                  </li>
                );
              }}
            </For>
          </ol>
        </div>
      </aside>
    </Show>
  );
}
