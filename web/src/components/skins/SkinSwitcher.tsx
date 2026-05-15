import { createSignal, Show } from "solid-js";
import { uiStore, setSkin, type SkinName } from "../../stores/ui";

const SKINS: Array<{ key: SkinName; label: string; preview: string }> = [
  { key: "editorial", label: "Editorial", preview: "E" },
  { key: "terminal",  label: "Terminal",  preview: "T" },
  { key: "winamp",    label: "Winamp",    preview: "W" },
  { key: "vinyl",     label: "Vinyl",     preview: "V" },
];

/// Inline (non-fixed) skin chooser. Designed to live inside a shared top-right
/// cluster alongside the CLOSE button — each skin component composes them.
export default function SkinSwitcher() {
  const [open, setOpen] = createSignal(false);
  return (
    <div style="position:relative;">
      <button class="label"
        onClick={() => setOpen(!open())}
        style="font-size:11px; padding:6px 12px; border:1px solid currentColor; opacity:0.85; white-space:nowrap;"
      >SKIN: {uiStore.skin.toUpperCase()}</button>

      <Show when={open()}>
        <div style="
          position:absolute; top:36px; right:0;
          background:rgba(250,250,247,0.96); backdrop-filter:blur(20px);
          border:1px solid rgba(0,0,0,0.15);
          padding:8px;
          display:grid; grid-template-columns:repeat(2, 64px); gap:6px;
          z-index:5;
        ">
          {SKINS.map((s) => (
            <button
              onClick={() => { setSkin(s.key); setOpen(false); }}
              title={s.label}
              style={`
                width:64px; height:64px;
                display:flex; align-items:center; justify-content:center;
                font-family:var(--font-mono); font-size:24px;
                border:1px solid ${uiStore.skin === s.key ? "var(--ink)" : "rgba(0,0,0,0.15)"};
                background:${uiStore.skin === s.key ? "var(--ink)" : "transparent"};
                color:${uiStore.skin === s.key ? "#fafaf7" : "var(--ink)"};
                cursor:pointer;
              `}
            >{s.preview}</button>
          ))}
        </div>
      </Show>
    </div>
  );
}
