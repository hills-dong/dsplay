import type { SkinProps } from "./types";
import SkinSwitcher from "./SkinSwitcher";

function fmt(s: number) {
  if (!isFinite(s) || s < 0) return "0:00";
  const m = Math.floor(s / 60);
  const r = Math.floor(s % 60).toString().padStart(2, "0");
  return `${m}:${r}`;
}

export default function VinylNowPlaying(props: SkinProps) {
  // Rotation tied to playback position so the disc visibly spins.
  const angle = () => (props.position * 60) % 360; // 1 rev per 6 seconds for visibility

  return (
    <section style="
      position:fixed; inset:0; z-index:200;
      background:
        radial-gradient(ellipse at 20% 30%, #3a2418 0%, #1a0f08 60%, #0a0604 100%);
      color:#d4af6a;
      font-family:Georgia, 'Iowan Old Style', serif;
      padding:48px 64px;
      display:flex; gap:64px; align-items:center; justify-content:center;
    ">
      {/* Disc */}
      <div style={`
        width:380px; height:380px; flex-shrink:0;
        border-radius:50%;
        background:
          radial-gradient(circle, #1a1a1a 28%, transparent 28.5%) center/100% 100% no-repeat,
          repeating-radial-gradient(circle, #1a1a1a 0px, #1a1a1a 2px, #0a0a0a 2.5px, #0a0a0a 4px),
          #000;
        box-shadow:
          0 12px 40px rgba(0,0,0,0.8),
          inset 0 0 30px rgba(212, 175, 106, 0.05);
        position:relative;
        transform:rotate(${angle()}deg);
        transition:transform 0.2s linear;
      `}>
        {/* label */}
        <div style="
          position:absolute; inset:0; margin:auto;
          width:130px; height:130px; border-radius:50%;
          background:radial-gradient(circle, #c44 50%, #800 100%);
          box-shadow:inset 0 0 0 2px #d4af6a;
          display:flex; align-items:center; justify-content:center;
          color:#1a0a05; font-style:italic; font-size:14px;
          text-align:center; padding:14px;
          overflow:hidden;
        ">
          <span style="overflow:hidden; text-overflow:ellipsis; line-height:1.2;">
            {props.track.album || "Side A"}
          </span>
        </div>
        {/* center pin */}
        <div style="position:absolute; inset:0; margin:auto; width:8px; height:8px; background:#d4af6a; border-radius:50%; z-index:2;"></div>
      </div>

      {/* Right column: info + controls */}
      <div style="flex:1; max-width:520px; min-width:0;">
        <div style="font-size:11px; letter-spacing:3px; text-transform:uppercase; opacity:0.6;">A side · Track</div>
        <h1 style="font-size:42px; font-style:italic; margin:8px 0 12px; line-height:1.15;">{props.track.title}</h1>
        <div style="font-size:15px; opacity:0.85; letter-spacing:2px;">{props.track.artist.toUpperCase()}</div>

        {/* Progress */}
        <div style="margin-top:36px;">
          <div onClick={(e) => {
            const target = e.currentTarget as HTMLDivElement;
            const rect = target.getBoundingClientRect();
            const ratio = (e.clientX - rect.left) / rect.width;
            props.onSeek(Math.max(0, Math.min(1, ratio)) * props.duration);
          }}
            style="height:1px; background:rgba(212,175,106,0.3); position:relative; cursor:pointer;"
          >
            {/* dot position uses `left:%` because transform:translateX(%) is
                relative to the element's own width, not the track width. */}
            <div style={`
              position:absolute;
              left:${(props.duration ? props.position / props.duration : 0) * 100}%;
              top:-3px; height:7px; width:7px; border-radius:50%;
              background:#d4af6a;
              transform:translateX(-50%);
            `}></div>
            <div style={`
              position:absolute; left:0; top:0; bottom:0;
              width:${(props.duration ? props.position / props.duration : 0) * 100}%;
              background:rgba(212,175,106,0.6);
            `}></div>
          </div>
          <div style="display:flex; justify-content:space-between; font-family:ui-monospace, monospace; font-size:11px; opacity:0.7; margin-top:10px; letter-spacing:1px;">
            <span>{fmt(props.position)}</span>
            <span>{fmt(props.duration)}</span>
          </div>
        </div>

        {/* Controls */}
        <div style="display:flex; gap:24px; margin-top:36px; align-items:center;">
          <button onClick={props.onPrev}
            style="background:transparent; color:#d4af6a; border:1px solid rgba(212,175,106,0.4); padding:10px 16px; font-family:inherit; font-style:italic; font-size:13px; letter-spacing:2px; cursor:pointer;"
          >⏮ prev</button>
          <button onClick={props.onPlayPause}
            style="background:#d4af6a; color:#1a0f08; border:1px solid #d4af6a; padding:14px 28px; font-family:inherit; font-style:italic; font-size:14px; letter-spacing:3px; cursor:pointer; min-width:120px;"
          >{props.isPlaying ? "pause" : "play"}</button>
          <button onClick={props.onNext}
            style="background:transparent; color:#d4af6a; border:1px solid rgba(212,175,106,0.4); padding:10px 16px; font-family:inherit; font-style:italic; font-size:13px; letter-spacing:2px; cursor:pointer;"
          >next ⏭</button>
        </div>
      </div>

      <div style="position:absolute; top:32px; right:32px; display:flex; gap:12px; align-items:flex-start; color:#d4af6a;">
        <button class="label" onClick={props.onClose}
          style="background:transparent; color:inherit; border:1px solid rgba(212,175,106,0.4);
                 padding:6px 12px; font-family:inherit; font-size:11px; cursor:pointer; white-space:nowrap;"
        >ESC</button>
        <SkinSwitcher />
      </div>
    </section>
  );
}
