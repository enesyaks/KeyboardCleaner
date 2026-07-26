#!/usr/bin/env bash
# Build KeyboardCleaner.app and create a release zip.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
DIST_DIR="$ROOT/dist"
APP_NAME="KeyboardCleaner"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

"$ROOT/Scripts/build.sh"

# Re-sign for distribution if Developer ID is available (optional here;
# Scripts/notarize.sh does the full Developer ID + notarize flow).
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  echo "==> Signing with \$CODESIGN_IDENTITY"
  codesign --force --deep --options runtime \
    --entitlements "$ROOT/Resources/KeyboardCleaner.entitlements" \
    --sign "$CODESIGN_IDENTITY" \
    "$APP_DIR"
fi

echo "==> Creating zip"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
echo "$SHA  $ZIP_NAME" > "$DIST_DIR/$ZIP_NAME.sha256"

echo "==> Package ready"
echo "    Zip:  $ZIP_PATH"
echo "    SHA256: $SHA"
echo "    Version: $VERSION"
