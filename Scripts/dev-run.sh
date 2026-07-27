#!/usr/bin/env bash
# Local dev loop: build (signed with the stable dev identity if set up),
# install to /Applications, and launch. Keeps the Accessibility grant across
# rebuilds once you've run ./Scripts/dev-sign-setup.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

export KBC_SIGN_IDENTITY="KeyboardCleaner Dev"
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$KBC_SIGN_IDENTITY"; then
  echo "⚠️  Stable identity '$KBC_SIGN_IDENTITY' not found."
  echo "    Run ./Scripts/dev-sign-setup.sh once so Accessibility survives rebuilds."
  echo "    Falling back to ad-hoc signing for now…"
  unset KBC_SIGN_IDENTITY
fi

"$ROOT/Scripts/build.sh"

echo "==> Installing to /Applications"
pkill -x KeyboardCleaner 2>/dev/null || true
sleep 1
rm -rf "/Applications/KeyboardCleaner.app"
cp -R "$ROOT/.build/KeyboardCleaner.app" "/Applications/"
open "/Applications/KeyboardCleaner.app"
echo "==> Launched /Applications/KeyboardCleaner.app"
