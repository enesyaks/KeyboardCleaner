# KeyboardCleaner

Menu bar app for macOS that locks your keyboard while you clean it. Mouse and trackpad stay active so you can unlock anytime.

**Author:** [enesyaks](https://github.com/enesyaks)  
**Requirements:** macOS 14 Sonoma or later

## Install with Homebrew

```bash
brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner
brew install --cask keyboard-cleaner
```

Update later with:

```bash
brew upgrade --cask keyboard-cleaner
```

Uninstall:

```bash
brew uninstall --cask keyboard-cleaner
```

## Manual install

1. Download the latest `.zip` from [Releases](https://github.com/enesyaks/KeyboardCleaner/releases)
2. Unzip and move `KeyboardCleaner.app` to **Applications**
3. Open the app (menu bar keyboard icon)
4. Grant **Accessibility** access when asked  
   System Settings → Privacy & Security → Accessibility

## Features

- Lock keyboard input while cleaning
- Menu bar only (no Dock icon)
- Custom emergency unlock shortcut (default `⌃⌥⇧⌘K`)
- Launch at login
- Onboarding on first launch

## Build from source

```bash
./Scripts/build.sh
open .build/KeyboardCleaner.app
```

### Release (maintainers)

1. **One-time Apple setup**
   - In Xcode → Settings → Accounts, download **Developer ID Application** certificate
   - Create an [app-specific password](https://appleid.apple.com)
   - Store notary credentials:
     ```bash
     xcrun notarytool store-credentials "KeyboardCleaner-notary" \
       --apple-id "YOUR_APPLE_ID" \
       --team-id "YOUR_TEAM_ID" \
       --password "app-specific-password"
     ```

2. **Sign, notarize, and package**
   ```bash
   export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
   ./Scripts/notarize.sh
   ```

3. **Publish GitHub release + refresh Homebrew cask**
   ```bash
   ./Scripts/release.sh
   git add Casks/keyboard-cleaner.rb
   git commit -m "Update Homebrew cask for v1.0.0"
   git push
   ```

   Without GitHub CLI, run `./Scripts/release.sh --skip-upload`, then upload `dist/KeyboardCleaner-VERSION.zip` on the Releases page manually.

Ad-hoc local package (no notarization):

```bash
./Scripts/package.sh
```

## License

Copyright © 2026 Enes (enesyaks). All rights reserved.
