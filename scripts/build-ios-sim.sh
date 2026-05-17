#!/usr/bin/env bash
# Build DSPlay for the iOS Simulator and assemble a runnable .app — no Xcode
# project, no swift-bundler (v2.0.7 public build cannot bundle iOS). The macOS
# path (scripts/build.sh / swift-bundler) is untouched.
#
# Usage: scripts/build-ios-sim.sh [debug|release]   (default: debug)
# Prints the assembled .app path on the last line.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CONFIG="${1:-debug}"
SDK="$(xcrun --show-sdk-path --sdk iphonesimulator)"
TRIPLE="arm64-apple-ios26.0-simulator"

BUILD_FLAGS=(
  --configuration "$CONFIG"
  --triple "$TRIPLE"
  -Xswiftc -sdk -Xswiftc "$SDK"
  -Xcc -isysroot -Xcc "$SDK"
  --product DSPlay
)

swift build "${BUILD_FLAGS[@]}" 1>&2

# The actual triple dir drops the version suffix (arm64-apple-ios-simulator),
# so resolve it instead of hardcoding.
BIN_DIR="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)"

APP="$REPO_ROOT/.build/ios-sim/DSPlay.app"
rm -rf "$APP"
mkdir -p "$APP"

cp "$BIN_DIR/DSPlay" "$APP/DSPlay"
cp "$REPO_ROOT/Packaging/iOS-Info.plist" "$APP/Info.plist"

# App-icon PNGs (no asset catalog — referenced by CFBundleIcons in the
# Info.plist; SpringBoard resolves @2x/@3x by basename).
cp "$REPO_ROOT"/Packaging/AppIcon-iOS/*.png "$APP/"

# SwiftPM resource bundle (StatusItem.png etc.). Unused on iOS but copied so
# Bundle.module lookups never fault.
if [ -d "$BIN_DIR/DSPlay_DSPlay.bundle" ]; then
  cp -R "$BIN_DIR/DSPlay_DSPlay.bundle" "$APP/"
fi

codesign --force --sign - "$APP" 1>&2

echo "$APP"
