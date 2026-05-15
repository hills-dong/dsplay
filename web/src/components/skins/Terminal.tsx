import type { SkinProps } from "./types";
import SkinSwitcher from "./SkinSwitcher";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "00:00";
  const m = Math.floor(s / 60).toString().padStart(2, "0");
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

function bar(progress: number, width = 38) {
  const filled = Math.max(0, Math.min(width, Math.round(progress * width)));
  return "#".repeat(filled) + "-".repeat(width - filled);
}

export default function TerminalNowPlaying(props: SkinProps) {
  const progress = () => (props.duration > 0 ? props.position / props.duration : 0);

  return (
    <section style="
      position:fixed; inset:0; z-index:200;
      background:#050805;
      color:#33ff66;
      font-family:'IBM Plex Mono', ui-monospace, 'Courier New', monospace;
      font-size:14px;
      line-height:1.6;
      padding:48px 64px;
      text-shadow:0 0 4px rgba(51,255,102,0.4);
      overflow:hidden;
    ">
      {/* Scanlines */}
      <div style="
        position:absolute; inset:0; pointer-events:none;
        background:repeating-linear-gradient(0deg, transparent 0px, transparent 2px, rgba(0,0,0,0.25) 2px, rgba(0,0,0,0.25) 3px);
      "></div>

      <div style="position:relative; max-width:780px;">
        <div style="opacity:0.6;">$ dsplay --now-playing</div>
        <div style="margin-top:18px;">┌─ NOW PLAYING ─────────────────────────────┐</div>
        <div style="margin-top:8px;">▸ {props.track.title}</div>
        <div style="opacity:0.75;">  {props.track.artist}</div>
        <div style="opacity:0.6;">  {props.track.album}</div>
        <div style="margin-top:20px;">[{bar(progress())}]  {Math.round(progress()*100)}%</div>
        <div style="margin-top:6px;">{fmt(props.position)} / {fmt(props.duration)}</div>

        <div style="margin-top:32px; display:flex; gap:20px;">
          <button onClick={props.onPrev}
            style="background:transparent; color:inherit; border:1px solid currentColor; padding:8px 14px; font:inherit; text-shadow:inherit; cursor:pointer;"
          >[ &lt;&lt; prev ]</button>
          <button onClick={props.onPlayPause}
            style="background:#33ff66; color:#050805; border:1px solid currentColor; padding:8px 14px; font:inherit; cursor:pointer;"
          >[ {props.isPlaying ? "pause" : "play "} ]</button>
          <button onClick={props.onNext}
            style="background:transparent; color:inherit; border:1px solid currentColor; padding:8px 14px; font:inherit; text-shadow:inherit; cursor:pointer;"
          >[ next &gt;&gt; ]</button>
        </div>

        <div style="margin-top:48px; opacity:0.5;">└────────────────────────────────────────────┘</div>
        <div style="margin-top:12px;">$ _</div>
      </div>

      <div style="position:absolute; top:32px; right:32px; z-index:211; display:flex; gap:12px; align-items:flex-start; color:#33ff66;">
        <button class="label" onClick={props.onClose}
          style="background:transparent; color:inherit; border:1px solid #33ff66;
                 padding:6px 12px; font-family:inherit; font-size:11px; cursor:pointer; white-space:nowrap;"
        >ESC</button>
        <SkinSwitcher />
      </div>
    </section>
  );
}
