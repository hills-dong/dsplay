#!/usr/bin/env bash
# Regenerates DSPlay/Resources/AppIcon.icns and DSPlay/Resources/StatusItem.png
# from scratch. Run once (or whenever the brand mark changes). The results
# are committed to git so normal `build.sh` runs don't need to re-render.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK=".build/icon"
rm -rf "$WORK"
mkdir -p "$WORK/AppIcon.iconset"

echo "make-icon.sh: rendering app-icon masters"
swift scripts/make-icon.swift --variant app-large --size 1024 --output "$WORK/large.png"
swift scripts/make-icon.swift --variant app-small --size 1024 --output "$WORK/small.png"

echo "make-icon.sh: downscaling large master (>=128px slots)"
for sz in 128 256 512 1024; do
  sips -z "$sz" "$sz" "$WORK/large.png" --out "$WORK/L-$sz.png" >/dev/null
done

echo "make-icon.sh: downscaling small master (<=64px slots)"
for sz in 16 32 64; do
  sips -z "$sz" "$sz" "$WORK/small.png" --out "$WORK/S-$sz.png" >/dev/null
done

ISET="$WORK/AppIcon.iconset"
cp "$WORK/S-16.png"   "$ISET/icon_16x16.png"
cp "$WORK/S-32.png"   "$ISET/icon_16x16@2x.png"
cp "$WORK/S-32.png"   "$ISET/icon_32x32.png"
cp "$WORK/S-64.png"   "$ISET/icon_32x32@2x.png"
cp "$WORK/L-128.png"  "$ISET/icon_128x128.png"
cp "$WORK/L-256.png"  "$ISET/icon_128x128@2x.png"
cp "$WORK/L-256.png"  "$ISET/icon_256x256.png"
cp "$WORK/L-512.png"  "$ISET/icon_256x256@2x.png"
cp "$WORK/L-512.png"  "$ISET/icon_512x512.png"
cp "$WORK/L-1024.png" "$ISET/icon_512x512@2x.png"

iconutil -c icns "$ISET" -o "DSPlay/Resources/AppIcon.icns"
echo "make-icon.sh: wrote DSPlay/Resources/AppIcon.icns"

echo "make-icon.sh: rendering menu bar status item PNG (44px @2x source)"
swift scripts/make-icon.swift --variant statusbar --size 44 \
  --output "DSPlay/Resources/StatusItem.png"
echo "make-icon.sh: wrote DSPlay/Resources/StatusItem.png"
