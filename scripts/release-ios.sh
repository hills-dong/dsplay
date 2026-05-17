#!/usr/bin/env bash
# Archive the iOS app and upload it to App Store Connect / TestFlight.
#
# Requires (from your paid Apple Developer account, hillsdong.sg@gmail.com):
#   DSPLAY_TEAM_ID    10-char Apple Developer Team ID
#   ASC_KEY_ID        App Store Connect API Key ID (10 chars)
#   ASC_ISSUER_ID     App Store Connect API Issuer ID (UUID)
#   and the key file at:
#                     ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
#
# The app record (Bundle ID app.dsplay) must already exist in App Store
# Connect. Signing cert + App Store provisioning profile are created
# automatically via the API key (-allowProvisioningUpdates).
#
# Usage:  DSPLAY_TEAM_ID=XXXXXXXXXX ASC_KEY_ID=XXXXXXXXXX \
#         ASC_ISSUER_ID=xxxxxxxx-.... bash scripts/release-ios.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

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
ARCHIVE=".build/DSPlay.xcarchive"
EXPORT=".build/export"
OPTS=".build/ExportOptions.plist"

echo "release-ios: regenerating Xcode project"
xcodegen generate >/dev/null

echo "release-ios: archiving (build $BUILD_NO)"
rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild archive \
  -project DSPlay.xcodeproj -scheme DSPlay \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$P8" \
  DEVELOPMENT_TEAM="$DSPLAY_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CURRENT_PROJECT_VERSION="$BUILD_NO" \
  | tail -3

sed "s/__TEAM_ID__/$DSPLAY_TEAM_ID/" Packaging/ExportOptions.plist > "$OPTS"

echo "release-ios: exporting .ipa"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$OPTS" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$P8" \
  | tail -3

IPA="$(/usr/bin/find "$EXPORT" -name '*.ipa' | head -1)"
[ -n "$IPA" ] || { echo "no .ipa produced"; exit 1; }
echo "release-ios: uploading $IPA"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "release-ios: done — build $BUILD_NO uploaded. It will appear in"
echo "App Store Connect → TestFlight after ~5-15 min of processing."
