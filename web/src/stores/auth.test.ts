import { describe, it, expect, beforeEach } from "vitest";
import { authStore, setAuthed, clearAuth } from "./auth";

beforeEach(() => clearAuth());

describe("authStore", () => {
  it("starts unauthenticated", () => {
    expect(authStore.isAuthed).toBe(false);
  });
  it("setAuthed populates fields", () => {
    setAuthed("https://x", "alice");
    expect(authStore.isAuthed).toBe(true);
    expect(authStore.url).toBe("https://x");
    expect(authStore.user).toBe("alice");
  });
});
