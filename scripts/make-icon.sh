#!/usr/bin/env bash
# Regenerates DSPlay/Resources/AppIcon.icns from scratch. Run once (or
# whenever you want to change the icon). The result is committed to git
# so normal `build.sh` runs don't need to re-render it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK=".build/icon"
rm -rf "$WORK"
mkdir -p "$WORK/AppIcon.iconset"

echo "make-icon.sh: rendering 1024px master"
swift scripts/make-icon.swift "$WORK/master.png"

echo "make-icon.sh: downscaling"
for sz in 16 32 64 128 256 512 1024; do
  sips -z "$sz" "$sz" "$WORK/master.png" --out "$WORK/$sz.png" >/dev/null
done

ISET="$WORK/AppIcon.iconset"
cp "$WORK/16.png"   "$ISET/icon_16x16.png"
cp "$WORK/32.png"   "$ISET/icon_16x16@2x.png"
cp "$WORK/32.png"   "$ISET/icon_32x32.png"
cp "$WORK/64.png"   "$ISET/icon_32x32@2x.png"
cp "$WORK/128.png"  "$ISET/icon_128x128.png"
cp "$WORK/256.png"  "$ISET/icon_128x128@2x.png"
cp "$WORK/256.png"  "$ISET/icon_256x256.png"
cp "$WORK/512.png"  "$ISET/icon_256x256@2x.png"
cp "$WORK/512.png"  "$ISET/icon_512x512.png"
cp "$WORK/1024.png" "$ISET/icon_512x512@2x.png"

iconutil -c icns "$ISET" -o "DSPlay/Resources/AppIcon.icns"
echo "make-icon.sh: wrote DSPlay/Resources/AppIcon.icns"
