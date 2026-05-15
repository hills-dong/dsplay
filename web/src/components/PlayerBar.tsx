import { Show } from "solid-js";
import { playerStore } from "../stores/player";
import { bridge } from "../bridge";
import { uiStore, setQueueOpen, setNowPlayingOpen } from "../stores/ui";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

const ICON_BTN = "border:1px solid var(--ink); padding:6px 10px; font-family:var(--font-mono); font-size:12px; min-width:34px;";
const ACTIVE_BTN = ICON_BTN + " background:var(--ink); color:#fafaf7;";

export default function PlayerBar() {
  const nextRepeat = (m: "off" | "all" | "one") => (m === "off" ? "all" : m === "all" ? "one" : "off");

  return (
    <Show when={playerStore.currentTrack}>
      <div style="
        position:fixed; left:0; right:0; bottom:0;
        height:var(--playerbar-h);
        background:rgba(250,250,247,0.94);
        backdrop-filter:blur(20px); -webkit-backdrop-filter:blur(20px);
        border-top:1px solid var(--ink);
        padding:14px 32px;
        display:grid;
        grid-template-columns:1fr auto 1fr;
        column-gap:32px; align-items:center; z-index:100;
      ">
        <div onClick={() => setNowPlayingOpen(true)}
          style="cursor:pointer; min-width:0;"
        >
          <div class="serif" style="font-size:16px; font-style:italic; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
            {playerStore.currentTrack!.title}
          </div>
          <div class="serif" style="font-size:12px; color:var(--mute); overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
            {playerStore.currentTrack!.artist} — {playerStore.currentTrack!.album}
          </div>
        </div>

        <div style="display:flex; gap:8px; align-items:center;">
          <button
            class="label"
            title="Shuffle"
            onClick={() => bridge.call("player.setShuffle", { value: !playerStore.shuffle })}
            style={playerStore.shuffle ? ACTIVE_BTN : ICON_BTN}
          >SHUF</button>
          <button class="label" title="Previous"
            onClick={() => bridge.call("player.prev", {} as Record<string, never>)}
            style={ICON_BTN}>⏮</button>
          <button class="label" title="Play / Pause"
            onClick={() => bridge.call("player.toggle", {} as Record<string, never>)}
            style={ICON_BTN + " min-width:60px;"}>
            {playerStore.state === "playing" ? "PAUSE" : "PLAY"}
          </button>
          <button class="label" title="Next"
            onClick={() => bridge.call("player.next", {} as Record<string, never>)}
            style={ICON_BTN}>⏭</button>
          <button
            class="label"
            title={`Repeat: ${playerStore.repeat}`}
            onClick={() => bridge.call("player.setRepeat", { mode: nextRepeat(playerStore.repeat) })}
            style={playerStore.repeat !== "off" ? ACTIVE_BTN : ICON_BTN}
          >
            {playerStore.repeat === "one" ? "RPT 1" : "RPT"}
          </button>
        </div>

        <div style="display:flex; gap:12px; align-items:center; justify-content:flex-end;">
          <span class="mono" style="font-size:12px; color:var(--mute);">
            {fmt(playerStore.position)} / {fmt(playerStore.duration)}
          </span>
          <button class="label"
            title={`Queue (${playerStore.queue.length})`}
            onClick={() => setQueueOpen(!uiStore.queueOpen)}
            style={uiStore.queueOpen ? ACTIVE_BTN : ICON_BTN}
          >QUEUE {playerStore.queue.length}</button>
        </div>
      </div>
    </Show>
  );
}
