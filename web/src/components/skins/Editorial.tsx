import type { SkinProps } from "./types";
import SkinSwitcher from "./SkinSwitcher";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

export default function EditorialNowPlaying(props: SkinProps) {
  const progress = () => (props.duration > 0 ? props.position / props.duration : 0);

  const handleSeekClick = (e: MouseEvent) => {
    const target = e.currentTarget as HTMLDivElement;
    const rect = target.getBoundingClientRect();
    const ratio = (e.clientX - rect.left) / rect.width;
    props.onSeek(Math.max(0, Math.min(1, ratio)) * props.duration);
  };

  return (
    <section style="
      position:fixed; inset:0; z-index:200;
      display:grid; grid-template-rows:auto 1fr auto; row-gap:24px;
      padding:48px 64px 48px 100px;
      overflow:hidden;
    ">
      {/* Drag strip for titlebar — covers full width above content. */}
      <div style="position:fixed; top:0; left:0; right:0; height:var(--titlebar-h); z-index:201; -webkit-app-region:drag;"></div>

      {/* Top bar: NOW PLAYING label only; CLOSE + SKIN buttons are anchored
          fixed-top-right so they share a single corner row. */}
      <header style="display:flex; align-items:baseline;">
        <span class="label" style="font-size:11px;">NOW PLAYING</span>
      </header>

      {/* Body: cover left, text right */}
      <div style="display:grid; grid-template-columns:minmax(280px, 1fr) 1fr; column-gap:64px; align-items:center;">
        <div style={`
          aspect-ratio:1/1;
          background-color:#ececea;
          ${props.coverUrl ? `background-image:url("${props.coverUrl}"); background-size:cover; background-position:center; background-repeat:no-repeat;` : ""}
          border:1px solid rgba(0,0,0,0.08);
          max-width:480px; margin:0 auto;
          width:100%;
        `}></div>

        <div style="display:flex; flex-direction:column; gap:14px; min-width:0;">
          <div class="label" style="font-size:11px;">{props.track.album}</div>
          <h1 class="serif" style="
            font-size:46px; font-weight:500; font-style:italic;
            line-height:1.1; margin:0;
            overflow:hidden;
          ">{props.track.title}</h1>
          <div class="serif" style="font-size:18px; color:var(--mute);">
            {props.track.artist}
          </div>

          {/* Seek bar */}
          <div style="margin-top:18px;">
            <div onClick={handleSeekClick}
              style="height:2px; background:rgba(0,0,0,0.15); position:relative; cursor:pointer;"
            >
              <div style={`position:absolute; left:0; top:0; bottom:0; width:${progress() * 100}%; background:var(--ink);`}></div>
            </div>
            <div class="mono" style="display:flex; justify-content:space-between; font-size:11px; color:var(--mute); margin-top:6px;">
              <span>{fmt(props.position)}</span>
              <span>{fmt(props.duration)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Transport controls */}
      <div style="display:flex; gap:24px; justify-content:center; align-items:center;">
        <button class="label" onClick={props.onPrev}
          style="font-size:14px; padding:14px 22px; border:1px solid var(--ink);"
        >⏮ PREV</button>
        <button class="label" onClick={props.onPlayPause}
          style="font-size:14px; padding:18px 36px; border:1px solid var(--ink); background:var(--ink); color:#fafaf7; min-width:140px;"
        >{props.isPlaying ? "PAUSE" : "PLAY"}</button>
        <button class="label" onClick={props.onNext}
          style="font-size:14px; padding:14px 22px; border:1px solid var(--ink);"
        >NEXT ⏭</button>
      </div>

      {/* Top-right cluster: CLOSE + SKIN switcher, side-by-side with a gap. */}
      <div style="position:fixed; top:36px; right:32px; z-index:202; display:flex; gap:12px; align-items:flex-start; -webkit-app-region:no-drag;">
        <button class="label" onClick={props.onClose}
          style="font-size:11px; padding:6px 12px; border:1px solid var(--ink); white-space:nowrap;"
        >✕ CLOSE</button>
        <SkinSwitcher />
      </div>
    </section>
  );
}
