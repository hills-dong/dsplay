#!/usr/bin/env bash
# Regenerates the brand assets from scratch:
#   - DSPlay/Resources/AppIcon.icns          (macOS app icon)
#   - DSPlay/Resources/StatusItem.png        (macOS menu-bar template)
#   - Packaging/AppIcon-iOS/*.png            (iOS app icon set)
# Run once (or whenever the brand mark changes). Results are committed so a
# normal build doesn't re-render.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK=".build/icon"
rm -rf "$WORK"
mkdir -p "$WORK/AppIcon.iconset"

# ---------- macOS .icns ----------
echo "make-icon.sh: rendering macOS app-icon master (1024)"
swift scripts/make-icon.swift --variant app --size 1024 --output "$WORK/app.png"

ISET="$WORK/AppIcon.iconset"
for spec in "16:icon_16x16" "32:icon_16x16@2x" "32:icon_32x32" \
            "64:icon_32x32@2x" "128:icon_128x128" "256:icon_128x128@2x" \
            "256:icon_256x256" "512:icon_256x256@2x" "512:icon_512x512" \
            "1024:icon_512x512@2x"; do
  sz="${spec%%:*}"; name="${spec##*:}"
  sips -z "$sz" "$sz" "$WORK/app.png" --out "$ISET/$name.png" >/dev/null
done
iconutil -c icns "$ISET" -o "DSPlay/Resources/AppIcon.icns"
echo "make-icon.sh: wrote DSPlay/Resources/AppIcon.icns"

# ---------- macOS menu-bar template ----------
echo "make-icon.sh: rendering menu-bar StatusItem (44px)"
swift scripts/make-icon.swift --variant statusbar --size 44 \
  --output "DSPlay/Resources/StatusItem.png"
echo "make-icon.sh: wrote DSPlay/Resources/StatusItem.png"

# ---------- iOS icon set ----------
echo "make-icon.sh: rendering iOS app-icon master (1024)"
IOS_DIR="Packaging/AppIcon-iOS"
mkdir -p "$IOS_DIR"
swift scripts/make-icon.swift --variant ios --size 1024 --output "$WORK/ios.png"

# Flat set used by the SIMULATOR path (scripts/build-ios-sim.sh).
sips -z 120 120 "$WORK/ios.png" --out "$IOS_DIR/AppIcon60x60@2x.png"   >/dev/null
sips -z 180 180 "$WORK/ios.png" --out "$IOS_DIR/AppIcon60x60@3x.png"   >/dev/null
sips -z 152 152 "$WORK/ios.png" --out "$IOS_DIR/AppIcon76x76@2x.png"   >/dev/null
sips -z 167 167 "$WORK/ios.png" --out "$IOS_DIR/AppIcon83.5x83.5@2x.png" >/dev/null
sips -z 1024 1024 "$WORK/ios.png" --out "$IOS_DIR/AppIcon1024.png" >/dev/null
echo "make-icon.sh: wrote $IOS_DIR/ (5 PNGs)"

# Full multi-size AppIcon.appiconset used by the TestFlight / App Store
# Xcode build (project.yml). A single-size icon only emits @2x on some
# toolchains — modern iPhones are @3x, so list every slot explicitly.
ASET_DIR="Packaging/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ASET_DIR"
rm -f "$ASET_DIR"/*.png
for px in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
  sips -z "$px" "$px" "$WORK/ios.png" --out "$ASET_DIR/icon_${px}.png" >/dev/null
done
cat > "$ASET_DIR/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom":"iphone","size":"20x20","scale":"2x","filename":"icon_40.png" },
    { "idiom":"iphone","size":"20x20","scale":"3x","filename":"icon_60.png" },
    { "idiom":"iphone","size":"29x29","scale":"2x","filename":"icon_58.png" },
    { "idiom":"iphone","size":"29x29","scale":"3x","filename":"icon_87.png" },
    { "idiom":"iphone","size":"40x40","scale":"2x","filename":"icon_80.png" },
    { "idiom":"iphone","size":"40x40","scale":"3x","filename":"icon_120.png" },
    { "idiom":"iphone","size":"60x60","scale":"2x","filename":"icon_120.png" },
    { "idiom":"iphone","size":"60x60","scale":"3x","filename":"icon_180.png" },
    { "idiom":"ipad","size":"20x20","scale":"1x","filename":"icon_20.png" },
    { "idiom":"ipad","size":"20x20","scale":"2x","filename":"icon_40.png" },
    { "idiom":"ipad","size":"29x29","scale":"1x","filename":"icon_29.png" },
    { "idiom":"ipad","size":"29x29","scale":"2x","filename":"icon_58.png" },
    { "idiom":"ipad","size":"40x40","scale":"1x","filename":"icon_40.png" },
    { "idiom":"ipad","size":"40x40","scale":"2x","filename":"icon_80.png" },
    { "idiom":"ipad","size":"76x76","scale":"1x","filename":"icon_76.png" },
    { "idiom":"ipad","size":"76x76","scale":"2x","filename":"icon_152.png" },
    { "idiom":"ipad","size":"83.5x83.5","scale":"2x","filename":"icon_167.png" },
    { "idiom":"ios-marketing","size":"1024x1024","scale":"1x","filename":"icon_1024.png" }
  ],
  "info" : { "author":"xcode", "version":1 }
}
JSON
echo "make-icon.sh: wrote $ASET_DIR/ (full appiconset)"
