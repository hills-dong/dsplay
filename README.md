# DSPlay

A native music player for Synology Audio Station — universal for **macOS** and **iOS / iPadOS**.

Fully native: one SwiftUI codebase, AppKit shell on macOS / UIKit on iOS, `AVQueuePlayer` streaming directly from your NAS. No web layer, no IPC bridge.

## Features

- Login to any Synology DSM (credentials stored locally — `~/Library/Application Support/DSPlay/credentials.json` at file mode 0600 on macOS, Keychain on iOS — with silent re-auth on session expiry)
- Search, browse artists / albums / playlists
- Queue with auto-advance, prev / next / shuffle / repeat
- Native Now Playing center, lock-screen / Control Center controls, media keys (F7/F8/F9 on Mac), AirPods controls, AirPlay route picker
- Full-screen NowPlaying view with 4 swappable skins: **Editorial** (default), **Terminal CRT**, **Winamp 90s**, **Vinyl**
- Background playback; macOS menubar status item with controls

## Requirements

Build (macOS app):
- macOS 14.0+
- Xcode Command Line Tools (`xcode-select --install`)
- [mint](https://github.com/yonaskolb/Mint) — `brew install mint`
- [swift-bundler](https://swiftbundler.dev) — pinned to `v2.0.7` via `Mintfile` (`mint bootstrap`)

Build (iOS app):
- Xcode.app (full install)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen` (project is generated from `project.yml`)
- For App Store / TestFlight: a paid Apple Developer account

Run / Install:
- macOS 14.0+ / iOS 26.0+

## Building from source

### macOS

```bash
bash scripts/build.sh   # builds the .app via swift-bundler + installs to /Applications
bash scripts/run.sh     # builds + launches
bash scripts/package.sh # builds + ad-hoc signs + makes dist/DSPlay-x.y.z.dmg
```

The `.app` lands in `.build/bundler/DSPlay.app`.

### iOS

```bash
xcodegen generate                 # regenerate DSPlay.xcodeproj from project.yml
bash scripts/build-ios-sim.sh     # build + assemble a runnable .app for the iOS Simulator
```

`scripts/build-ios-sim.sh` builds without Xcode/swift-bundler (the public swift-bundler
v2.0.7 cannot bundle iOS). The macOS path is untouched. It prints the assembled `.app`
path on the last line — install it into a booted simulator with `xcrun simctl install`.

## Installation (macOS, personal use)

```bash
bash scripts/package.sh
open dist/DSPlay-0.2.0.dmg
# drag DSPlay.app to Applications
```

Because the DMG is ad-hoc signed, macOS Gatekeeper may complain the first time. Right-click DSPlay.app → Open → confirm. From then on it launches normally.

## macOS signing & notarization (for distribution to others)

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

## iOS — TestFlight / App Store

`scripts/release-ios.sh` archives the iOS app and uploads it to App Store Connect.
Signing cert + provisioning profile are created automatically via an App Store
Connect API key (`-allowProvisioningUpdates`). The app record (Bundle ID
`app.dsplay`) must already exist in App Store Connect.

```bash
DSPLAY_TEAM_ID=XXXXXXXXXX \
ASC_KEY_ID=XXXXXXXXXX \
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
bash scripts/release-ios.sh
```

Requires the API key file at `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8`.

## Repository layout

```
DSPlay/             Native Swift sources (shared by macOS + iOS)
  App/              DSPlayApp (SwiftUI App) + AppDelegate + IOSAppDelegate + AppModel + MainWindowController
  UI/               Theme, UIState, RootView, Navigation, Platform shim + Components
  Views/            LoginView, MainShellView, Search/Artists/Albums/Playlists (+Detail),
                    NowPlaying/ (4 skins + switcher)
  Synology/         URLSession client + DTOs + SynologyError
  Player/           AVQueuePlayer wrapper + PlayerState + AudioSession + NowPlayingCenter + RemoteCommands
  System/           Credentials store + NSStatusItem (macOS)
  Resources/        StatusItem.png, AppIcon.icns (macOS-only, gated)
Packaging/          Assets.xcassets (app icon), Device-Info.plist (iOS)
project.yml         XcodeGen spec for the signable iOS build
scripts/            build.sh, run.sh, package.sh (macOS),
                    build-ios-sim.sh, release-ios.sh, asc-submit.py, asc-jwt.swift (iOS)
docs/               Landing page + privacy policy
```

State flows one way: `PlaybackEngine` mutates an `@Observable PlayerState`;
SwiftUI views (main window **and** the menu-bar popover) observe it directly —
no polling, no bridge.

## Development

```bash
swift build                   # compile (macOS)
swift test --no-parallel      # unit tests (the mock URLProtocol uses shared static state)
bash scripts/run.sh           # build + launch the macOS .app
bash scripts/build-ios-sim.sh # build for the iOS Simulator
```

## Releases

Tagged versions of the macOS app are built by GitHub Actions
(`.github/workflows/release.yml`) on a `macos-14` runner. Push a tag like
`v0.2.0` and the workflow produces a DMG attached to the GitHub Release.
macOS builds are ad-hoc signed only — see "macOS signing & notarization"
above. iOS builds ship via TestFlight / App Store (see above).
