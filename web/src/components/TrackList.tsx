import { For } from "solid-js";
import type { Track } from "../types";
import { playerStore } from "../stores/player";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

export default function TrackList(props: { tracks: Track[]; onPick: (t: Track) => void }) {
  return (
    <ol style="list-style:none; padding:0; margin:0;">
      <For each={props.tracks}>
        {(track, i) => {
          const isCurrent = () => playerStore.currentTrack?.id === track.id;
          return (
            <li
              onClick={() => props.onPick(track)}
              style={`
                display:grid; grid-template-columns:36px 1fr auto; column-gap:16px;
                align-items:baseline; padding:14px 0;
                border-bottom:1px solid rgba(0,0,0,0.08); cursor:pointer;
              `}
            >
              <span class="mono" style={`color:${isCurrent() ? "var(--accent)" : "var(--mute)"};`}>
                {isCurrent() ? "▸" : (i() + 1).toString().padStart(2, "0")}
              </span>
              <div>
                <div class="serif" style={`font-size:19px; color:${isCurrent() ? "var(--accent)" : "var(--ink)"};`}>
                  {track.title}
                </div>
                <div class="serif" style="font-size:13px; color:var(--mute); margin-top:2px;">
                  {track.artist} — {track.album}
                </div>
              </div>
              <span class="mono" style="color:var(--mute); font-size:13px;">{fmt(track.duration)}</span>
            </li>
          );
        }}
      </For>
    </ol>
  );
}
