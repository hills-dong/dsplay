# DSPlay

A native-feel macOS music player for Synology Audio Station.

Built with a Swift/AppKit shell hosting WKWebView + SolidJS (per `yetone/native-feel-skill`). AVQueuePlayer handles streaming directly from your NAS.

## Features

- Login to any Synology DSM (credentials stored locally at `~/Library/Application Support/DSPlay/credentials.json` with file mode 0600, silent re-auth on session expiry)
- Search, browse artists / albums / playlists
- Queue with auto-advance, prev / next / shuffle / repeat
- Native Now Playing center + media keys (F7/F8/F9) + AirPods controls
- Full-screen NowPlaying view with 4 swappable skins: **Editorial** (default), **Terminal CRT**, **Winamp 90s**, **Vinyl**
- Background playback (window close keeps audio going), menubar status item with controls

## Requirements

Build:
- macOS 14.0+
- Xcode Command Line Tools (`xcode-select --install`)
- [mint](https://github.com/yonaskolb/Mint) — `brew install mint`
- [swift-bundler](https://swiftbundler.dev) — `mint install stackotter/swift-bundler@main`
- [pnpm](https://pnpm.io) — `brew install pnpm`
- [quicktype](https://quicktype.io) — `brew install quicktype`

Run / Install:
- macOS 14.0+

## Building from source

```bash
bash scripts/build.sh   # builds web bundle + IPC codegen + .app via swift-bundler
bash scripts/run.sh     # builds + launches
bash scripts/package.sh # builds + ad-hoc signs + makes dist/DSPlay-x.y.z.dmg
```

The `.app` lands in `.build/bundler/DSPlay.app`.

## Installation (personal use)

```bash
bash scripts/package.sh
open dist/DSPlay-0.1.0.dmg
# drag DSPlay.app to Applications
```

Because the DMG is ad-hoc signed, macOS Gatekeeper may complain the first time. Right-click DSPlay.app → Open → confirm. From then on it launches normally.

## Signing & Notarization (for distribution to others)

The bundled `scripts/package.sh` produces an **ad-hoc signed** `.app`, which works on the machine that built it but trips Gatekeeper warnings on other Macs. To ship publicly, you need:

1. An Apple Developer account ($99/year) with a **Developer ID Application** certificate.
2. Xcode.app installed (required for `xcrun notarytool` and `xcrun stapler`).
3. Replace the `codesign --sign -` line in `scripts/package.sh` with:
   ```bash
   codesign --sign "Developer ID Application: Your Name (TEAMID)" \
            --options runtime \
            --deep --force \
            "$APP_PATH"
   ```
4. After DMG creation:
   ```bash
   xcrun notarytool submit "$DIST_DIR/$DMG_NAME" \
     --apple-id "you@example.com" \
     --team-id TEAMID \
     --password "@keychain:notarytool-password" \
     --wait
   xcrun stapler staple "$DIST_DIR/$DMG_NAME"
   ```

Until you do this, share the DMG only with people who trust right-click-Open.

## Repository layout

```
DSPlay/             Swift sources (~1300 LOC)
  App/              AppDelegate + MainWindowController
  Bridge/           BridgeRouter / BridgeServer / BridgeEvents
  Synology/         URLSession client + DTOs
  Player/           AVQueuePlayer wrapper + NowPlayingCenter + RemoteCommands
  System/           Credentials store (file-backed) + NSStatusItem
  WebHost/          WKWebView controller + dsplay:// scheme handler
  Generated/        IPCTypes.swift (codegen, committed)
  Resources/WebDist  Vite bundle output (gitignored, built at compile)
web/                SolidJS UI (~1100 LOC)
  src/routes/       Login, Search, Artists, ArtistDetail, Albums, Playlists, PlaylistDetail, NowPlaying
  src/components/   AppShell, PlayerBar, QueueDrawer, TrackList, AlbumCard
  src/components/skins/  Editorial, Terminal, Winamp, Vinyl + SkinSwitcher
  src/stores/       auth, player, ui
shared/ipc-schema.ts   TS-as-source-of-truth for IPC types (codegen feeds Swift side)
scripts/            build.sh, run.sh, gen-ipc.sh, build-web.sh, package.sh, make-icon.{sh,swift}
```

## Development

```bash
swift build                   # Swift-only compile
swift test                    # Swift unit tests (Swift Testing via SPM)
(cd web && pnpm test)         # Vitest
bash scripts/run.sh           # build + launch the .app
```

The web UI gets HMR while developing if you run `pnpm --filter web dev` from `web/`, but for the desktop app you need to rebuild via `scripts/build.sh` after web changes.

## Releases

Tagged versions are built by GitHub Actions (`.github/workflows/release.yml`) on a `macos-14` runner. Push a tag like `v0.1.0` and the workflow produces a DMG attached to the GitHub Release. Builds are ad-hoc signed only — see "Signing & Notarization" above.
