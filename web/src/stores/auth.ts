import { createStore } from "solid-js/store";

export interface AuthState {
  isAuthed: boolean;
  url: string;
  user: string;
}

const initial: AuthState = { isAuthed: false, url: "", user: "" };
const [authStore, setStore] = createStore<AuthState>(initial);
export { authStore };

export function setAuthed(url: string, user: string) {
  setStore({ isAuthed: true, url, user });
}
export function clearAuth() {
  setStore(initial);
}
