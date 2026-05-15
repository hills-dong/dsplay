import { createMemo } from "solid-js";
import type { SkinProps } from "./types";
import SkinSwitcher from "./SkinSwitcher";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

export default function WinampNowPlaying(props: SkinProps) {
  // 12 VU bars; fake "music"-driven intensity from playback rate + time.
  const vu = createMemo(() => {
    const t = Math.floor(props.position * 4);
    return Array.from({ length: 12 }, (_, i) => {
      const seed = (i * 7 + t * 3) % 13;
      return props.isPlaying ? seed > i / 2 : false;
    });
  });

  return (
    <section style="
      position:fixed; inset:0; z-index:200;
      background:linear-gradient(180deg, #2a3540 0%, #11181f 100%);
      font-family:'Tahoma', 'MS Sans Serif', sans-serif;
      color:#c0c8d0;
      padding:48px 64px;
      display:flex; align-items:center; justify-content:center;
    ">
      <div style="
        width:520px;
        background:linear-gradient(180deg, #5a6b78 0%, #2a3540 100%);
        border:1px solid #0a1018;
        padding:14px;
        box-shadow:0 14px 40px rgba(0,0,0,0.6), inset 0 1px 0 #7a8a98;
      ">
        {/* Title bar */}
        <div style="background:linear-gradient(180deg, #4a5b68 0%, #1a2028 100%); padding:4px 10px; font-size:11px; color:#fff; display:flex; justify-content:space-between; border-bottom:1px solid #0a1018;">
          <span>■ DSPlay 1.0</span>
          <span style="opacity:0.6;">_ □ ×</span>
        </div>

        {/* LCD */}
        <div style="
          background:#0a0a0a;
          border:1px solid #2a3540;
          margin-top:12px; padding:12px 14px;
          color:#00ff66;
          font-family:ui-monospace, monospace;
          text-shadow:0 0 4px #00ff66;
          box-shadow:inset 0 0 12px rgba(0,255,102,0.2);
        ">
          <div style="font-size:28px; letter-spacing:3px;">{fmt(props.position)}</div>
          <div style="font-size:10px; opacity:0.85; margin-top:4px; text-transform:uppercase; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
            ► {props.track.title} — {props.track.artist}
          </div>
          {/* VU bars */}
          <div style="display:flex; gap:2px; margin-top:10px;">
            {vu().map((on) => (
              <span style={`
                flex:1; height:14px;
                background:linear-gradient(180deg, #ff3300 0%, #ffcc00 30%, #00ff66 70%);
                opacity:${on ? 1 : 0.25};
              `}></span>
            ))}
          </div>
        </div>

        {/* Buttons */}
        <div style="display:flex; gap:4px; margin-top:12px;">
          {[
            { label: "◄◄", onClick: props.onPrev },
            { label: props.isPlaying ? "❚❚" : "►", onClick: props.onPlayPause },
            { label: "■",  onClick: () => props.onSeek(0) },
            { label: "►►", onClick: props.onNext },
          ].map((b) => (
            <button onClick={b.onClick}
              style="
                flex:1; padding:8px;
                background:linear-gradient(180deg, #5a6b78 0%, #2a3540 100%);
                border:1px solid #0a1018; border-top-color:#7a8a98;
                color:#fff; font-size:14px; cursor:pointer;
              "
            >{b.label}</button>
          ))}
        </div>

        {/* Progress slider */}
        <div style="margin-top:14px; height:10px; background:#1a2028; border:1px solid #0a1018; position:relative; cursor:pointer;"
          onClick={(e) => {
            const target = e.currentTarget as HTMLDivElement;
            const rect = target.getBoundingClientRect();
            const ratio = (e.clientX - rect.left) / rect.width;
            props.onSeek(Math.max(0, Math.min(1, ratio)) * props.duration);
          }}
        >
          <div style={`position:absolute; left:0; top:0; bottom:0; width:${(props.duration ? props.position / props.duration : 0) * 100}%; background:linear-gradient(180deg, #5a8aa8 0%, #2a4a68 100%);`}></div>
        </div>

        <div style="display:flex; justify-content:space-between; margin-top:6px; font-size:10px; opacity:0.7;">
          <span>{fmt(props.position)}</span>
          <span>{fmt(props.duration)}</span>
        </div>
      </div>

      <div style="position:absolute; top:32px; right:32px; display:flex; gap:12px; align-items:flex-start; color:#c0c8d0;">
        <button class="label" onClick={props.onClose}
          style="background:transparent; color:inherit; border:1px solid #c0c8d0;
                 padding:6px 12px; font-family:inherit; font-size:11px; cursor:pointer; white-space:nowrap;"
        >ESC</button>
        <SkinSwitcher />
      </div>
    </section>
  );
}
