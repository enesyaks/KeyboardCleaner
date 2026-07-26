#!/usr/bin/env bash
# Sign with Developer ID and notarize for Gatekeeper.
#
# Prerequisites (one-time):
#   1. Xcode → Settings → Accounts → download "Developer ID Application" certificate
#   2. Create an app-specific password at https://appleid.apple.com
#   3. Store credentials:
#        xcrun notarytool store-credentials "KeyboardCleaner-notary" \
#          --apple-id "YOUR_APPLE_ID@email.com" \
#          --team-id "YOUR_TEAM_ID" \
#          --password "app-specific-password"
#
# Usage:
#   export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#   ./Scripts/notarize.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
DIST_DIR="$ROOT/dist"
APP_NAME="KeyboardCleaner"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
ENTITLEMENTS="$ROOT/Resources/KeyboardCleaner.entitlements"
NOTARY_PROFILE="${NOTARY_PROFILE:-KeyboardCleaner-notary}"

if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  echo "error: Set CODESIGN_IDENTITY to your Developer ID Application certificate."
  echo "  Example:"
  echo "    export CODESIGN_IDENTITY=\"Developer ID Application: Enes Yaks (XXXXXXXXXX)\""
  echo "  List identities with:"
  echo "    security find-identity -v -p codesigning"
  exit 1
fi

"$ROOT/Scripts/build.sh"

echo "==> Signing with Developer ID (hardened runtime)"
codesign --force --deep --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_DIR"

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "==> Zipping for notarization"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "==> Submitting to Apple notary service (profile: $NOTARY_PROFILE)"
xcrun notarytool submit "$ZIP_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "==> Stapling ticket"
# Staple the .app, then re-zip so users get a Gatekeeper-friendly package
xcrun stapler staple "$APP_DIR"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
echo "$SHA  $ZIP_NAME" > "$DIST_DIR/$ZIP_NAME.sha256"

spctl --assess --type execute -vv "$APP_DIR" || true

echo "==> Notarized package ready"
echo "    Zip:  $ZIP_PATH"
echo "    SHA256: $SHA"
echo "    Next: ./Scripts/release.sh"
