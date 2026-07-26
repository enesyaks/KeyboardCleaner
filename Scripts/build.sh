#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build"
APP_NAME="KeyboardCleaner"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos14.0"

echo "==> Compiling sources ($TARGET)"
mkdir -p "$BUILD_DIR/bin"

SOURCES=(
  "$ROOT/Sources/KeyboardCleaner/AccessibilityManager.swift"
  "$ROOT/Sources/KeyboardCleaner/KeyboardBlocker.swift"
  "$ROOT/Sources/KeyboardCleaner/LaunchAtLogin.swift"
  "$ROOT/Sources/KeyboardCleaner/AppSettings.swift"
  "$ROOT/Sources/KeyboardCleaner/AppState.swift"
  "$ROOT/Sources/KeyboardCleaner/MenuBarPanel.swift"
  "$ROOT/Sources/KeyboardCleaner/SettingsView.swift"
  "$ROOT/Sources/KeyboardCleaner/OnboardingView.swift"
  "$ROOT/Sources/KeyboardCleaner/KeyboardCleanerApp.swift"
)

swiftc -parse-as-library \
  -O \
  -sdk "$SDK" \
  -target "$TARGET" \
  -framework AppKit \
  -framework SwiftUI \
  -framework ApplicationServices \
  -framework Carbon \
  -framework ServiceManagement \
  -o "$BUILD_DIR/bin/$APP_NAME" \
  "${SOURCES[@]}"

echo "==> Assembling .app bundle"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/bin/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp "$ROOT/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"

# Simple PkgInfo
echo -n 'APPL????' > "$APP_DIR/Contents/PkgInfo"

chmod +x "$MACOS_DIR/$APP_NAME"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "==> Ready: $APP_DIR"
echo "    Open with: open \"$APP_DIR\""
echo "    Note: Grant Accessibility access in System Settings."
