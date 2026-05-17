# DSPlay

A native-feel macOS music player for Synology Audio Station.

Fully native: SwiftUI views in an AppKit shell, `AVQueuePlayer` streaming directly from your NAS. No web layer, no IPC bridge.

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
- [swift-bundler](https://swiftbundler.dev) — pinned to `v2.0.7` via `Mintfile` (`mint bootstrap`)

Run / Install:
- macOS 14.0+

## Building from source

```bash
bash scripts/build.sh   # builds the .app via swift-bundler + installs to /Applications
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
DSPlay/             Native Swift sources
  App/              DSPlayApp (SwiftUI App) + AppDelegate + AppModel + MainWindowController
  UI/               Theme, UIState, RootView + Components (CoverImage, TrackList, DetailHero, AlbumCard)
  Views/            LoginView, MainShellView, Search/Artists/Albums/Playlists (+Detail),
                    PlayerBarView, QueueDrawerView, NowPlaying/ (4 skins + switcher)
  Synology/         URLSession client + DTOs + SynologyError
  Player/           AVQueuePlayer wrapper + PlayerState + NowPlayingCenter + RemoteCommands + MiniPlayerView
  System/           Credentials store (file-backed) + NSStatusItem
  Resources/        StatusItem.png, AppIcon.icns
scripts/            build.sh, run.sh, package.sh, make-icon.{sh,swift}
```

State flows one way: `PlaybackEngine` mutates an `@Observable PlayerState`;
SwiftUI views (main window **and** the menu-bar popover) observe it directly —
no polling, no bridge.

## Development

```bash
swift build                   # compile
swift test --no-parallel      # unit tests (the mock URLProtocol uses shared static state)
bash scripts/run.sh           # build + launch the .app
```

## Releases

Tagged versions are built by GitHub Actions (`.github/workflows/release.yml`) on a `macos-14` runner. Push a tag like `v0.1.0` and the workflow produces a DMG attached to the GitHub Release. Builds are ad-hoc signed only — see "Signing & Notarization" above.
