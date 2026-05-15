import { createStore } from "solid-js/store";
import type { Track, IPCEvent } from "../types";

export interface PlayerState {
  currentTrack: Track | null;
  state: "idle" | "loading" | "playing" | "paused" | "error";
  position: number;
  duration: number;
  // M2 additions
  queue: Track[];
  queueIndex: number;        // -1 = empty queue
  shuffle: boolean;
  repeat: "off" | "all" | "one";
}

const initial: PlayerState = {
  currentTrack: null,
  state: "idle",
  position: 0,
  duration: 0,
  queue: [],
  queueIndex: -1,
  shuffle: false,
  repeat: "off",
};
const [playerStore, setStore] = createStore<PlayerState>(initial);
export { playerStore };

export function applyPlayerEvent(event: IPCEvent) {
  switch (event.type) {
    case "player.stateChange":
      setStore({
        state: event.payload.state,
        currentTrack: event.payload.track ?? playerStore.currentTrack,
      });
      break;
    case "player.timeUpdate":
      setStore({ position: event.payload.position, duration: event.payload.duration });
      break;
    case "player.ended":
      // Don't reset state — auto-advance from the Swift side will trigger
      // a fresh "loading"/"playing" stateChange right after.
      setStore({ position: 0 });
      break;
    case "player.error":
      setStore({ state: "error" });
      break;
    case "queue.update":
      setStore({
        queue: event.payload.queue,
        queueIndex: event.payload.index,
        shuffle: event.payload.shuffle,
        repeat: event.payload.repeat,
        // Keep currentTrack in sync with the new index.
        currentTrack: event.payload.index >= 0 && event.payload.index < event.payload.queue.length
          ? event.payload.queue[event.payload.index]
          : null,
      });
      break;
    default:
      break;
  }
}

export function resetPlayer() {
  setStore(initial);
}
