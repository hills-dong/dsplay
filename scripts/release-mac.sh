#!/usr/bin/env bash
# Archive the macOS app and upload it to App Store Connect (Mac App Store).
# Mirrors scripts/release-ios.sh. The local swift-bundler path
# (scripts/build.sh) is untouched — this is the *sandboxed, signed* build.
#
# Requires (same Apple Developer account / API key as iOS):
#   DSPLAY_TEAM_ID    10-char Apple Developer Team ID
#   ASC_KEY_ID        App Store Connect API Key ID (10 chars)
#   ASC_ISSUER_ID     App Store Connect API Issuer ID (UUID)
#   and the key file at:
#                     ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
#
# The app record (Bundle ID app.dsplay) and its macOS platform must already
# exist in App Store Connect. Signing cert + Mac App Store provisioning
# profile are created automatically via the API key (-allowProvisioningUpdates).
#
# Usage:  DSPLAY_TEAM_ID=XXXXXXXXXX ASC_KEY_ID=XXXXXXXXXX \
#         ASC_ISSUER_ID=xxxxxxxx-.... bash scripts/release-mac.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# Saved release credentials (Team ID / API key / Issuer / review phone).
# shellcheck disable=SC1090
[ -f "$HOME/.appstoreconnect/dsplay-release.env" ] && \
  . "$HOME/.appstoreconnect/dsplay-release.env"

: "${DSPLAY_TEAM_ID:?set DSPLAY_TEAM_ID}"
: "${ASC_KEY_ID:?set ASC_KEY_ID}"
: "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"

P8="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
[ -f "$P8" ] || { echo "missing API key: $P8"; exit 1; }

BUILD_NO="$(date +%Y%m%d%H%M)"          # monotonic, unique per upload
ARCHIVE=".build/DSPlay-mac.xcarchive"
EXPORT=".build/export-mac"
OPTS=".build/ExportOptions-macOS.plist"

echo "release-mac: regenerating Xcode project"
xcodegen generate >/dev/null

echo "release-mac: archiving (build $BUILD_NO)"
rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild archive \
  -project DSPlay.xcodeproj -scheme DSPlay-macOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$P8" \
  DEVELOPMENT_TEAM="$DSPLAY_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CURRENT_PROJECT_VERSION="$BUILD_NO" \
  | tail -3

sed "s/__TEAM_ID__/$DSPLAY_TEAM_ID/" Packaging/ExportOptions-macOS.plist > "$OPTS"

echo "release-mac: exporting .pkg"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$OPTS" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$P8" \
  | tail -3

PKG="$(/usr/bin/find "$EXPORT" -name '*.pkg' | head -1)"
[ -n "$PKG" ] || { echo "no .pkg produced"; exit 1; }
echo "release-mac: uploading $PKG"
xcrun altool --upload-app -f "$PKG" -t macos \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "release-mac: done — build $BUILD_NO uploaded. It appears in"
echo "App Store Connect → macOS App after ~5-15 min of processing."
echo "Then: bash scripts/submit-mac.sh   (configures metadata + submits)"
