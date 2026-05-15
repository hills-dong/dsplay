import { JSX, Show } from "solid-js";
import { useLocation, useNavigate } from "@solidjs/router";
import PlayerBar from "./PlayerBar";
import QueueDrawer from "./QueueDrawer";
import NowPlaying from "../routes/NowPlaying";
import { uiStore } from "../stores/ui";
import { playerStore } from "../stores/player";

const NAV: Array<{ label: string; path: string }> = [
  { label: "SEARCH",    path: "/search" },
  { label: "ARTISTS",   path: "/artists" },
  { label: "ALBUMS",    path: "/albums" },
  { label: "PLAYLISTS", path: "/playlists" },
];

export default function AppShell(props: { children?: JSX.Element }) {
  const loc = useLocation();
  const nav = useNavigate();
  const active = (p: string) => loc.pathname === p || loc.pathname.startsWith(p + "/");
  const hasPlayer = () => !!playerStore.currentTrack;
  return (
    <>
      <Show when={!uiStore.nowPlayingOpen}>
        {/* macOS titlebar drag strip — leaves room for traffic-lights, allows
            click-and-drag from the very top of the window. */}
        <div style="
          position:fixed; top:0; left:0; right:0;
          height:var(--titlebar-h);
          z-index:60;
          -webkit-app-region:drag;
        "></div>

        {/* DSPLAY header — fixed beneath the drag strip. */}
        <header style="
          position:fixed; top:var(--titlebar-h); left:0; right:0;
          height:var(--topnav-h);
          padding:0 32px 0 100px;     /* extra left padding so DSPLAY clears the traffic-lights */
          display:flex; align-items:center; justify-content:space-between;
          background:rgba(250,250,247,0.92);
          backdrop-filter:blur(20px); -webkit-backdrop-filter:blur(20px);
          border-bottom:1px solid var(--rule);
          z-index:50;
          -webkit-app-region:drag;
        ">
          <span class="serif" style="font-size:22px; font-weight:700; letter-spacing:-0.02em;">DSPLAY</span>
          <nav style="display:flex; gap:18px; -webkit-app-region:no-drag;">
            {NAV.map((item) => (
              <button
                class="label"
                onClick={() => nav(item.path)}
                style={`font-size:11px; color:${active(item.path) ? "var(--ink)" : "var(--mute)"}; ${active(item.path) ? "text-decoration:underline;" : ""}`}
              >{item.label}</button>
            ))}
          </nav>
        </header>

        {/* Scrolling content region — bounded between the header and the
            PlayerBar (which only takes space when playing). */}
        <main style={`
          position:fixed;
          top:calc(var(--titlebar-h) + var(--topnav-h));
          left:0; right:0;
          bottom:${hasPlayer() ? "var(--playerbar-h)" : "0px"};
          overflow-y:auto; overflow-x:hidden;
          overscroll-behavior:contain;
        `}>
          {props.children}
        </main>

        <PlayerBar />
        <QueueDrawer />
      </Show>
      <Show when={uiStore.nowPlayingOpen}>
        <NowPlaying />
      </Show>
    </>
  );
}
