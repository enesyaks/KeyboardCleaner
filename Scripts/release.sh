#!/usr/bin/env bash
# Create a GitHub Release and upload the packaged zip.
# Updates Casks/keyboard-cleaner.rb with version + sha256.
#
# Prerequisites:
#   - git remote pointing at https://github.com/enesyaks/KeyboardCleaner.git
#   - GitHub CLI (gh) authenticated, OR upload the zip manually on github.com
#   - Run package.sh first so dist/KeyboardCleaner-VERSION.zip exists
#
# Usage:
#   ./Scripts/release.sh           # uses version from Info.plist
#   ./Scripts/release.sh --skip-upload   # only refresh the cask sha/version
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT/dist"
APP_NAME="KeyboardCleaner"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
CASK_PATH="$ROOT/Casks/keyboard-cleaner.rb"
TAG="v${VERSION}"
SKIP_UPLOAD=0

if [[ "${1:-}" == "--skip-upload" ]]; then
  SKIP_UPLOAD=1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "error: Missing $ZIP_PATH"
  echo "  Run ./Scripts/package.sh first."
  exit 1
fi

SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

echo "==> Updating Homebrew cask (version $VERSION, sha256 $SHA)"
cat > "$CASK_PATH" <<EOF
cask "keyboard-cleaner" do
  version "${VERSION}"
  sha256 "${SHA}"

  url "https://github.com/enesyaks/KeyboardCleaner/releases/download/v#{version}/KeyboardCleaner-#{version}.zip"
  name "KeyboardCleaner"
  desc "Lock your Mac keyboard while you clean it"
  homepage "https://github.com/enesyaks/KeyboardCleaner"

  depends_on macos: ">= :sonoma"

  app "KeyboardCleaner.app"

  zap trash: [
    "~/Library/Preferences/com.enes.KeyboardCleaner.plist",
  ]
end
EOF

echo "==> Cask written to $CASK_PATH"

if [[ "$SKIP_UPLOAD" -eq 1 ]]; then
  echo "==> Skipping GitHub upload (--skip-upload)"
  echo "    Commit the cask change, then create a release and upload $ZIP_NAME manually."
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "==> gh (GitHub CLI) not found."
  echo "    1. Commit & push the updated cask"
  echo "    2. Open https://github.com/enesyaks/KeyboardCleaner/releases/new"
  echo "    3. Tag: $TAG"
  echo "    4. Upload: $ZIP_PATH"
  echo "    Users can then:"
  echo "      brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner"
  echo "      brew install --cask keyboard-cleaner"
  exit 0
fi

cd "$ROOT"
if ! git diff --quiet -- "$CASK_PATH" 2>/dev/null || ! git diff --cached --quiet -- "$CASK_PATH" 2>/dev/null; then
  echo "==> Tip: commit the updated Casks/keyboard-cleaner.rb before or after the release"
fi

echo "==> Creating GitHub release $TAG"
if gh release view "$TAG" >/dev/null 2>&1; then
  echo "    Release $TAG already exists — uploading asset (clobber)"
  gh release upload "$TAG" "$ZIP_PATH" --clobber
else
  gh release create "$TAG" "$ZIP_PATH" \
    --title "KeyboardCleaner $VERSION" \
    --notes "KeyboardCleaner ${VERSION}

## Install with Homebrew
\`\`\`bash
brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner
brew install --cask keyboard-cleaner
\`\`\`

## Manual install
Download **${ZIP_NAME}**, unzip, move **KeyboardCleaner.app** to Applications.

Grant **Accessibility** access on first use (System Settings → Privacy & Security → Accessibility).
"
fi

echo "==> Release published: https://github.com/enesyaks/KeyboardCleaner/releases/tag/$TAG"
echo "    Install:"
echo "      brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner"
echo "      brew install --cask keyboard-cleaner"
