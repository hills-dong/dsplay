#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "build.sh: [1/5] web bundle"
bash scripts/build-web.sh

echo "build.sh: [2/5] IPC codegen"
bash scripts/gen-ipc.sh

echo "build.sh: [3/5] swift-bundler bundle"
# Pin to v2.0.7 — `mint run swift-bundler` (no version) resolves to `main`,
# which fails to clone and uses a newer TOML schema incompatible with
# Bundler.toml.
mint run swift-bundler@v2.0.7 bundle

APP_PATH="$(find .build/bundler -maxdepth 4 -name 'DSPlay.app' -type d 2>/dev/null | head -1 || true)"
if [ -z "$APP_PATH" ]; then
  echo "build.sh: FATAL — could not locate built DSPlay.app" >&2
  exit 1
fi

# Drop the icon into the bundle. Info.plist already references AppIcon
# (set in Bundler.toml). Without this file, Launchpad/Finder show the
# generic blueprint icon (the same "ghost" look as Claude Code URL Handler).
echo "build.sh: [4/5] install AppIcon.icns into bundle"
if [ -f DSPlay/Resources/AppIcon.icns ]; then
  cp DSPlay/Resources/AppIcon.icns "$APP_PATH/Contents/Resources/AppIcon.icns"
else
  echo "  warning: DSPlay/Resources/AppIcon.icns missing — run scripts/make-icon.sh" >&2
fi

# swift-bundler v2.0.7 silently drops custom keys under [apps.*.plist], so
# inject LSUIElement here. Without it the app briefly shows a Dock icon at
# launch before NSApp.setActivationPolicy(.accessory) takes effect.
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP_PATH/Contents/Info.plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :LSUIElement true" "$APP_PATH/Contents/Info.plist"

# swift-bundler signs only the executable, leaving resources unsigned
# (`code has no resources but signature indicates they must be present`),
# which breaks Finder/Dock double-click launch. Re-sign deep so the
# resources we just dropped in are covered too.
echo "build.sh: [5/5] re-sign bundle (ad-hoc, deep) + install to /Applications"
codesign --deep --force --sign - "$APP_PATH" >/dev/null
echo "  signed $APP_PATH"

# Sync the freshly built bundle into /Applications so Launchpad and the
# Dock pick it up. `ditto` replaces atomically and preserves attrs.
DEST="/Applications/DSPlay.app"
if [ -d "$DEST" ]; then
  rm -rf "$DEST"
fi
ditto "$APP_PATH" "$DEST"
# Recently macOS sometimes caches the icon — touch nudges Launch Services.
touch "$DEST"
echo "  installed $DEST"
