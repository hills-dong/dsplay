import { onMount, createSignal, Show } from "solid-js";
import { Router, Route, Navigate } from "@solidjs/router";
import LoginView from "./routes/Login";
import SearchView from "./routes/Search";
import ArtistsView from "./routes/Artists";
import ArtistDetailView from "./routes/ArtistDetail";
import AlbumsView from "./routes/Albums";
import AlbumDetailView from "./routes/AlbumDetail";
import PlaylistsView from "./routes/Playlists";
import PlaylistDetailView from "./routes/PlaylistDetail";
import AppShell from "./components/AppShell";
import { authStore, setAuthed, clearAuth } from "./stores/auth";
import { applyPlayerEvent } from "./stores/player";
import { bridge } from "./bridge";

export default function App() {
  const [ready, setReady] = createSignal(false);

  onMount(async () => {
    bridge.onEvent((event) => {
      if (event.type === "auth.expired") clearAuth();
      else applyPlayerEvent(event);
    });

    try {
      const res = await bridge.call("auth.loadSaved", {});
      if (res.autoLoggedIn && res.url && res.user) {
        setAuthed(res.url, res.user);
      }
    } catch {
      // ignore
    } finally {
      setReady(true);
    }
  });

  return (
    <Show when={ready()}>
      <Router>
        <Route path="/" component={() => <Navigate href={authStore.isAuthed ? "/search" : "/login"} />} />
        <Route path="/login" component={LoginView} />
        <Route path="/search" component={() => (
          authStore.isAuthed
            ? <AppShell><SearchView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/artists" component={() => (
          authStore.isAuthed
            ? <AppShell><ArtistsView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/artist/:name" component={() => (
          authStore.isAuthed
            ? <AppShell><ArtistDetailView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/albums" component={() => (
          authStore.isAuthed
            ? <AppShell><AlbumsView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/album/:artist/:album" component={() => (
          authStore.isAuthed
            ? <AppShell><AlbumDetailView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/playlists" component={() => (
          authStore.isAuthed
            ? <AppShell><PlaylistsView /></AppShell>
            : <Navigate href="/login" />
        )} />
        <Route path="/playlist/:id" component={() => (
          authStore.isAuthed
            ? <AppShell><PlaylistDetailView /></AppShell>
            : <Navigate href="/login" />
        )} />
      </Router>
    </Show>
  );
}
