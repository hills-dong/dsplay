import { describe, it, expect, beforeEach } from "vitest";
import { playerStore, applyPlayerEvent, resetPlayer } from "./player";

const sample = { id: "1", title: "Re: Stacks", artist: "Bon Iver", album: "For Emma", duration: 401 };

beforeEach(() => resetPlayer());

describe("playerStore", () => {
  it("starts idle", () => {
    expect(playerStore.state).toBe("idle");
  });

  it("stateChange updates track", () => {
    applyPlayerEvent({ type: "player.stateChange", payload: { state: "playing", track: sample as any } });
    expect(playerStore.state).toBe("playing");
    expect(playerStore.currentTrack?.id).toBe("1");
  });

  it("timeUpdate updates position/duration", () => {
    applyPlayerEvent({ type: "player.timeUpdate", payload: { position: 12, duration: 100 } });
    expect(playerStore.position).toBe(12);
    expect(playerStore.duration).toBe(100);
  });

  it("ended resets position (auto-advance keeps state)", () => {
    applyPlayerEvent({ type: "player.stateChange", payload: { state: "playing", track: sample as any } });
    applyPlayerEvent({ type: "player.ended", payload: {} });
    // State is not reset to idle — Swift side will send a new stateChange after auto-advance.
    expect(playerStore.position).toBe(0);
  });

  it("queue.update populates queue + index + flags", () => {
    const tracks = [
      { id: "1", title: "A", artist: "X", album: "Y", duration: 100 },
      { id: "2", title: "B", artist: "X", album: "Y", duration: 200 },
    ] as any;
    applyPlayerEvent({
      type: "queue.update",
      payload: { queue: tracks, index: 1, shuffle: true, repeat: "all" },
    });
    expect(playerStore.queue).toHaveLength(2);
    expect(playerStore.queueIndex).toBe(1);
    expect(playerStore.shuffle).toBe(true);
    expect(playerStore.repeat).toBe("all");
    expect(playerStore.currentTrack?.id).toBe("2");
  });

  it("queue.update with empty queue clears currentTrack", () => {
    applyPlayerEvent({
      type: "queue.update",
      payload: { queue: [], index: -1, shuffle: false, repeat: "off" },
    });
    expect(playerStore.queue).toHaveLength(0);
    expect(playerStore.queueIndex).toBe(-1);
    expect(playerStore.currentTrack).toBeNull();
  });
});
