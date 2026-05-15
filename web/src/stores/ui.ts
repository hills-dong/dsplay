import { createStore } from "solid-js/store";

export type SkinName = "editorial" | "terminal" | "winamp" | "vinyl";

export interface UIState {
  queueOpen: boolean;
  nowPlayingOpen: boolean;
  skin: SkinName;
}

const SKIN_KEY = "dsplay.skin";
const readSkin = (): SkinName => {
  try {
    const v = localStorage.getItem(SKIN_KEY);
    if (v === "editorial" || v === "terminal" || v === "winamp" || v === "vinyl") return v;
  } catch {}
  return "editorial";
};

const initial: UIState = {
  queueOpen: false,
  nowPlayingOpen: false,
  skin: readSkin(),
};
const [uiStore, setStore] = createStore<UIState>(initial);
export { uiStore };

export function setQueueOpen(open: boolean) { setStore("queueOpen", open); }
export function setNowPlayingOpen(open: boolean) { setStore("nowPlayingOpen", open); }
export function setSkin(skin: SkinName) {
  setStore("skin", skin);
  try { localStorage.setItem(SKIN_KEY, skin); } catch {}
}
