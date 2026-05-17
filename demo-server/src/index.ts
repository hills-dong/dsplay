// Mock Synology Audio Station server for App Store review of "DS Music".
// Implements exactly the endpoints DSPlay's SynologyClient calls, with a
// tiny synthetic catalog and generated (royalty-free) tone audio so the
// reviewer can sign in, browse and play. Also serves the privacy / support
// pages. Deploy: `wrangler deploy` (uses existing OAuth session).

import cover0 from "../assets/cover0.jpg";
import cover1 from "../assets/cover1.jpg";
import cover2 from "../assets/cover2.jpg";
import cover3 from "../assets/cover3.jpg";
import cover4 from "../assets/cover4.jpg";
const COVERS: ArrayBuffer[] = [cover0, cover1, cover2, cover3, cover4] as any;

const CONTACT = "hillsdong.sg@gmail.com";

// ---- demo catalog -----------------------------------------------------
interface Song {
  id: string; title: string; artist: string; album: string;
  albumArtist: string; year: number; cover: number; freq: number;
}
const DUR = 24; // seconds of generated audio per track
const A = "Aurora Skies", M = "The Midnight Hours", C = "Coast & Loft";
const SONGS: Song[] = [
  { id: "s1",  title: "First Light",  artist: A, album: "Aurora",     albumArtist: A, year: 2024, cover: 0, freq: 220 },
  { id: "s2",  title: "Polar Glow",   artist: A, album: "Aurora",     albumArtist: A, year: 2024, cover: 0, freq: 262 },
  { id: "s3",  title: "Solstice",     artist: A, album: "Aurora",     albumArtist: A, year: 2024, cover: 0, freq: 330 },
  { id: "s4",  title: "Neon Rain",    artist: M, album: "Midnight",   albumArtist: M, year: 2023, cover: 1, freq: 247 },
  { id: "s5",  title: "After Hours",  artist: M, album: "Midnight",   albumArtist: M, year: 2023, cover: 1, freq: 294 },
  { id: "s6",  title: "City Lights",  artist: M, album: "Midnight",   albumArtist: M, year: 2023, cover: 1, freq: 392 },
  { id: "s7",  title: "Tide",         artist: C, album: "Coastline",  albumArtist: C, year: 2025, cover: 2, freq: 196 },
  { id: "s8",  title: "Salt Air",     artist: C, album: "Coastline",  albumArtist: C, year: 2025, cover: 2, freq: 349 },
  { id: "s9",  title: "Harbor",       artist: C, album: "Coastline",  albumArtist: C, year: 2025, cover: 2, freq: 440 },
  { id: "s10", title: "Dust",         artist: C, album: "Lo-Fi Loft", albumArtist: C, year: 2024, cover: 3, freq: 233 },
  { id: "s11", title: "Warm Tape",    artist: C, album: "Lo-Fi Loft", albumArtist: C, year: 2024, cover: 3, freq: 277 },
  { id: "s12", title: "Slow Sunday",  artist: C, album: "Lo-Fi Loft", albumArtist: C, year: 2024, cover: 3, freq: 311 },
];
const PLAYLIST = { id: "demo-mix", name: "Demo Mix", type: "normal",
                   songIds: ["s1", "s4", "s7", "s10"] };

const songById = (id: string) => SONGS.find(s => s.id === id);

function rawSong(s: Song) {
  return {
    id: s.id, title: s.title, path: `/music/${s.album}/${s.id}.wav`,
    additional: {
      song_tag: { album: s.album, artist: s.artist, album_artist: s.albumArtist },
      song_audio: {
        duration: DUR, bitrate: 705600, frequency: 22050, channel: 1,
        filesize: 22050 * 2 * DUR + 44, container: "wav", codec: "pcm",
      },
    },
  };
}

const J = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), {
    status, headers: { "content-type": "application/json",
                       "access-control-allow-origin": "*" } });
const ok = (data: unknown) => J({ success: true, data });

// ---- WAV tone synthesis ----------------------------------------------
function wav(freq: number): Uint8Array {
  const rate = 22050, n = rate * DUR;
  const buf = new ArrayBuffer(44 + n * 2);
  const v = new DataView(buf);
  const w = (o: number, s: string) => { for (let i = 0; i < s.length; i++) v.setUint8(o + i, s.charCodeAt(i)); };
  w(0, "RIFF"); v.setUint32(4, 36 + n * 2, true); w(8, "WAVE");
  w(12, "fmt "); v.setUint32(16, 16, true); v.setUint16(20, 1, true);
  v.setUint16(22, 1, true); v.setUint32(24, rate, true);
  v.setUint32(28, rate * 2, true); v.setUint16(32, 2, true);
  v.setUint16(34, 16, true); w(36, "data"); v.setUint32(40, n * 2, true);
  for (let i = 0; i < n; i++) {
    const t = i / rate;
    // soft attack/release envelope so it doesn't click
    const env = Math.min(1, t * 4) * Math.min(1, (DUR - t) * 2);
    const s = (Math.sin(2 * Math.PI * freq * t)
             + 0.35 * Math.sin(2 * Math.PI * freq * 2 * t)
             + 0.18 * Math.sin(2 * Math.PI * (freq * 1.5) * t)) / 1.53;
    v.setInt16(44 + i * 2, Math.max(-1, Math.min(1, s * env)) * 9000, true);
  }
  return new Uint8Array(buf);
}

function audioResponse(req: Request, bytes: Uint8Array): Response {
  const total = bytes.byteLength;
  const range = req.headers.get("range");
  const base = {
    "content-type": "audio/wav",
    "accept-ranges": "bytes",
    "cache-control": "no-store",
  };
  const m = range && /bytes=(\d+)-(\d*)/.exec(range);
  if (m) {
    const start = parseInt(m[1], 10);
    const end = m[2] ? parseInt(m[2], 10) : total - 1;
    return new Response(bytes.subarray(start, end + 1), {
      status: 206,
      headers: { ...base, "content-range": `bytes ${start}-${end}/${total}`,
                 "content-length": String(end - start + 1) },
    });
  }
  return new Response(bytes, { status: 200,
    headers: { ...base, "content-length": String(total) } });
}

// ---- pages ------------------------------------------------------------
const page = (title: string, body: string) => `<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>DS Music — ${title}</title><style>
body{margin:0;font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;color:#1c1c1e;background:#fafafa}
.w{max-width:680px;margin:0 auto;padding:56px 22px 80px}.m{font-size:30px;font-weight:800;letter-spacing:-.5px}
.m span{color:#e0392f}h1{font-size:24px;margin:34px 0 8px}h2{font-size:18px;margin:26px 0 6px}
p,li{color:#3a3a3c}a{color:#e0392f}code{background:#eee;padding:2px 6px;border-radius:5px}
footer{margin-top:46px;font-size:13px;color:#8a8a8e}</style></head><body><div class="w">
<div class="m">DS MUSIC<span>.</span></div>${body}
<footer>DS Music is not affiliated with or endorsed by Synology Inc.</footer></div></body></html>`;

const PRIVACY = page("Privacy Policy", `<h1>Privacy Policy</h1>
<p class="date" style="color:#8a8a8e;font-size:14px">Last updated: 17 May 2026</p>
<p>DS Music is a client for your own Synology Audio Station. We keep your data
on your devices and your own server.</p>
<h2>Data we collect</h2><p><strong>None.</strong> The developer collects, stores
and shares no personal data. No analytics, ads, tracking or third-party SDKs.</p>
<h2>Credentials &amp; server address</h2><p>The server address, username and
password you enter are stored only on your device (iOS Keychain / local
storage) and sent only to the Synology server you specify. They are never sent
to the developer or any third party.</p>
<h2>Music &amp; network</h2><p>Audio, metadata and artwork are fetched directly
from the server you connect to. The app communicates only with that server.</p>
<h2>Children</h2><p>The app collects no data from anyone.</p>
<h2>Contact</h2><p><a href="mailto:${CONTACT}">${CONTACT}</a></p>`);

const SUPPORT = page("Support", `<h1>Support</h1>
<p>DS Music streams music from your own Synology Audio Station. It is not a
streaming service and has no catalog of its own.</p>
<h2>Getting started</h2><ol><li>Make sure Audio Station is running on your
Synology NAS.</li><li>Enter your NAS address, Synology username and
password.</li><li>Browse Artists, Albums, Playlists or Search, and play.</li></ol>
<h2>Contact</h2><p><a href="mailto:${CONTACT}">${CONTACT}</a></p>
<p><a href="/privacy">Privacy Policy</a></p>`);

const HOME = page("Demo", `<h1>DS Music — demo server</h1>
<p>This host is a self-contained mock of Synology Audio Station used for App
Store review of the DS Music iOS app. Point the app's server field here and
sign in with the review credentials.</p>
<h2>Links</h2><p><a href="/privacy">Privacy Policy</a> · <a href="/support">Support</a></p>`);

// ---- router -----------------------------------------------------------
export default {
  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);
    const p = url.pathname;
    const q = url.searchParams;
    const method = q.get("method") || "";

    if (p === "/" ) return new Response(HOME, { headers: { "content-type": "text/html" } });
    if (p === "/privacy") return new Response(PRIVACY, { headers: { "content-type": "text/html" } });
    if (p === "/support") return new Response(SUPPORT, { headers: { "content-type": "text/html" } });

    // Auth
    if (p.endsWith("/webapi/entry.cgi") && q.get("api") === "SYNO.API.Auth") {
      if (method === "login") return ok({ sid: "demo-sid", did: "demo" });
      if (method === "logout") return J({ success: true });
      return ok({ sid: "demo-sid" });
    }

    // AudioStation APIs
    if (p.endsWith("/AudioStation/artist.cgi")) {
      const names = [...new Set(SONGS.map(s => s.artist))];
      return ok({ total: names.length, artists: names.map(name => ({ name })) });
    }

    if (p.endsWith("/AudioStation/album.cgi")) {
      const seen = new Map<string, Song>();
      for (const s of SONGS) if (!seen.has(s.album)) seen.set(s.album, s);
      const albums = [...seen.values()].map(s => ({
        name: s.album, album_artist: s.albumArtist,
        display_artist: s.albumArtist, year: s.year }));
      return ok({ total: albums.length, albums });
    }

    if (p.endsWith("/AudioStation/playlist.cgi")) {
      if (method === "getinfo") {
        const songs = PLAYLIST.songIds.map(id => rawSong(songById(id)!));
        return ok({ playlists: [{ id: PLAYLIST.id,
          additional: { songs } }] });
      }
      return ok({ playlists: [{ id: PLAYLIST.id, name: PLAYLIST.name,
        type: PLAYLIST.type }] });
    }

    if (p.endsWith("/AudioStation/song.cgi")) {
      const aa = q.get("album_artist"), ar = q.get("artist");
      let list = SONGS;
      if (aa) list = SONGS.filter(s => s.albumArtist === aa);
      else if (ar) list = SONGS.filter(s => s.artist === ar);
      return ok({ total: list.length, songs: list.map(rawSong) });
    }

    if (p.endsWith("/AudioStation/search.cgi")) {
      const k = (q.get("keyword") || "").toLowerCase();
      const list = SONGS.filter(s =>
        s.title.toLowerCase().includes(k) || s.artist.toLowerCase().includes(k)
        || s.album.toLowerCase().includes(k));
      return ok({ songTotal: list.length, songs: list.map(rawSong) });
    }

    if (p.endsWith("/AudioStation/cover.cgi")) {
      const s = songById(q.get("id") || "");
      const buf = COVERS[s ? s.cover : 0];
      return new Response(buf, { headers: { "content-type": "image/jpeg",
        "cache-control": "public, max-age=86400" } });
    }

    if (p.endsWith("/AudioStation/stream.cgi")) {
      const s = songById(q.get("id") || "");
      return audioResponse(req, wav(s ? s.freq : 220));
    }

    return J({ success: false, error: { code: 404 } }, 404);
  },
};
