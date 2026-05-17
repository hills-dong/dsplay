#!/usr/bin/env bash
# scripts/package.sh — build a release .app and wrap it in a distributable DMG.
#
# For personal use (this machine): ad-hoc signed, runs without Gatekeeper hassle.
# For distribution to others: see README.md "Signing & Notarization" section.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

VERSION="$(grep '^version' Bundler.toml | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
DMG_NAME="DSPlay-${VERSION}.dmg"
DIST_DIR="dist"
APP_PATH=".build/bundler/DSPlay.app"

echo "package.sh: [1/2] swift-bundler release build"
mint run swift-bundler@v2.0.7 bundle --configuration release 2>&1 | tail -3

# Sign ad-hoc (so the OS will run it on this machine without quarantine fuss).
# Use --deep so the inner DSPlay_DSPlay.bundle resource bundle is signed too.
echo "package.sh: ad-hoc sign"
codesign --sign - --deep --force "$APP_PATH"

echo "package.sh: [2/2] DMG"
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME"

# Build a folder layout: DSPlay.app + symlink to /Applications
STAGING=$(mktemp -d)
trap "rm -rf $STAGING" EXIT
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "DSPlay $VERSION" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$DMG_NAME" \
  2>&1 | tail -3

# Show final file
ls -lh "$DIST_DIR/$DMG_NAME"
echo ""
echo "✅ Done. Distribute: $DIST_DIR/$DMG_NAME"
echo "   Mount it, drag DSPlay.app to Applications, eject."
