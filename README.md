# KeyboardCleaner

Menu bar app for macOS that locks your keyboard while you clean it. Mouse and trackpad stay active so you can unlock anytime.

**Author:** [enesyaks](https://github.com/enesyaks)  
**Requirements:** macOS 14 Sonoma or later

## Install with Homebrew

```bash
brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner
brew install --cask kbcler
```

If Homebrew asks you to confirm a third-party tap/cask, type `y` to proceed. You can also install with the fully qualified name:

```bash
brew install --cask enesyaks/keyboardcleaner/kbcler
```

Update later with:

```bash
brew upgrade --cask kbcler
```

Uninstall:

```bash
brew uninstall --cask kbcler
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

```bash
./Scripts/package.sh
./Scripts/release.sh
git add Casks/kbcler.rb
git commit -m "Update Homebrew cask for v1.0.0"
git push
```

Without GitHub CLI, run `./Scripts/release.sh --skip-upload`, then upload `dist/KeyboardCleaner-VERSION.zip` on the Releases page manually.

## License

Copyright © 2026 Enes (enesyaks). All rights reserved.
