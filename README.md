<div align="center">

<img src="Resources/AppIcon.png" width="128" height="128" alt="KeyboardCleaner icon" />

# KeyboardCleaner

### Lock your Mac keyboard while you clean it — mouse stays free

Wipe every key without triggering a single keystroke. KeyboardCleaner lives in the
menu bar, disables keyboard input on demand, and keeps your trackpad and mouse
working so you can unlock the moment you're done.

<br />

![Platform](https://img.shields.io/badge/platform-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![macOS 14+](https://img.shields.io/badge/macOS-14_Sonoma+-1B8A78?style=for-the-badge)
![Menu bar app](https://img.shields.io/badge/menu_bar-only-E07A3D?style=for-the-badge)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?style=for-the-badge&logo=swift&logoColor=white)

<br />

**[⬇ Install](#-install)** · **[✨ Features](#-features)** · **[⚙ How it works](#-how-it-works)** · **[🛠 Build from source](#-build-from-source)**

</div>

<br />

---

## ⚡ Install

### Homebrew (recommended)

```bash
brew tap enesyaks/keyboardcleaner https://github.com/enesyaks/KeyboardCleaner
brew install --cask kbcler
```

> If Homebrew asks you to confirm a third-party tap/cask, type `y` to proceed.
> You can also use the fully qualified name: `brew install --cask enesyaks/keyboardcleaner/kbcler`

<table>
<tr>
<td width="50%">

**Update**

```bash
brew upgrade --cask kbcler
```

</td>
<td width="50%">

**Uninstall**

```bash
brew uninstall --cask kbcler
```

</td>
</tr>
</table>

### Manual install

| Step | Action |
|:----:|:-------|
| **1** | Download the latest `.zip` from [**Releases**](https://github.com/enesyaks/KeyboardCleaner/releases) |
| **2** | Unzip and drag `KeyboardCleaner.app` into **Applications** |
| **3** | Open the app — look for the ⌨️ icon in the menu bar |
| **4** | Grant **Accessibility** access when asked *(System Settings → Privacy & Security → Accessibility)* |

<br />

> [!IMPORTANT]
> **"KeyboardCleaner cannot be verified" on first launch?**
> KeyboardCleaner is open-source and *ad-hoc signed* — it isn't notarized through
> a paid Apple Developer account, so macOS Gatekeeper shows a warning. The app is
> safe; you just need to allow it once.
>
> **Homebrew installs** clear this automatically. If it still appears, run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/KeyboardCleaner.app
> ```
> or reinstall with `brew reinstall --cask --no-quarantine kbcler`.
>
> **Manual (.zip) installs** — pick either:
> - **Right-click** the app → **Open** → **Open** in the dialog, **or**
> - Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**, **or**
> - Run the `xattr` command above.

<br />

---

## ✨ Features

<table>
<tr>
<td width="33%" valign="top" align="center">

### 🔒
**Instant keyboard lock**

One click disables every key so you can scrub between them freely.

</td>
<td width="33%" valign="top" align="center">

### 🖱
**Mouse stays alive**

Trackpad and mouse keep working — no lockout, no panic.

</td>
<td width="33%" valign="top" align="center">

### 📊
**Cleaning timer**

Live session timer shows exactly how long the keyboard's been locked.

</td>
</tr>
<tr>
<td width="33%" valign="top" align="center">

### 🆘
**Emergency unlock**

Custom escape shortcut, default `⌃⌥⇧⌘K`, always frees you.

</td>
<td width="33%" valign="top" align="center">

### 🎯
**Menu bar only**

No Dock clutter. Lives quietly in the top-right corner.

</td>
<td width="33%" valign="top" align="center">

### 🚀
**Launch at login**

Ready in the menu bar every time you sign in to your Mac.

</td>
</tr>
</table>

<br />

---

## ⚙ How it works

```
   ┌──────────────┐        ┌───────────────────┐        ┌──────────────┐
   │  Click Lock  │  ───▶  │  Keyboard frozen  │  ───▶  │    Unlock    │
   │  in menu bar │        │  Mouse still free │        │  & you're done│
   └──────────────┘        └───────────────────┘        └──────────────┘
```

KeyboardCleaner installs a low-level `CGEventTap` at the session level. While locked,
every `keyDown`, `keyUp`, and modifier event is swallowed before it reaches any app —
so wiping across the keys can't type, delete, or trigger a shortcut. Mouse and
trackpad events flow through untouched, and your emergency shortcut is the one key
combo that's always allowed through to unlock.

> **Why Accessibility permission?** macOS only lets trusted apps observe and block
> keyboard input. The permission is required once; nothing leaves your Mac.

<br />

---

## 🛠 Build from source

**Requirements:** macOS 14 Sonoma or later · Swift toolchain (Xcode / Command Line Tools)

```bash
git clone https://github.com/enesyaks/KeyboardCleaner
cd KeyboardCleaner
./Scripts/build.sh
open .build/KeyboardCleaner.app
```

<details>
<summary><b>📦 Release (maintainers)</b></summary>

<br />

```bash
./Scripts/package.sh
./Scripts/release.sh
git add Casks/kbcler.rb
git commit -m "Update Homebrew cask for v1.0.0"
git push
```

Without the GitHub CLI, run `./Scripts/release.sh --skip-upload`, then upload
`dist/KeyboardCleaner-VERSION.zip` on the Releases page manually.

</details>

<br />

---

## 📁 Project layout

```
KeyboardCleaner/
├── Sources/KeyboardCleaner/
│   ├── KeyboardCleanerApp.swift   # App entry, menu bar scene, onboarding window
│   ├── KeyboardBlocker.swift      # CGEventTap that swallows keyboard events
│   ├── AppState.swift             # Lock state, session timer, permission checks
│   ├── AppSettings.swift          # Persisted prefs + emergency shortcut (KeyChord)
│   ├── AccessibilityManager.swift # AXIsProcessTrusted permission handling
│   ├── LaunchAtLogin.swift        # SMAppService login-item registration
│   ├── MenuBarPanel.swift         # Main menu bar popover UI
│   ├── SettingsView.swift         # Settings panel + shortcut recorder
│   └── OnboardingView.swift       # First-launch walkthrough
├── Resources/                     # Icon, Info.plist, entitlements
├── Scripts/                       # build / package / release helpers
└── Casks/kbcler.rb                # Homebrew cask definition
```

<br />

---

<div align="center">

**Author:** [enesyaks](https://github.com/enesyaks) &nbsp;·&nbsp; Requires macOS 14 Sonoma+

Copyright © 2026 Enes (enesyaks). All rights reserved.

<sub>Made for anyone who's ever been afraid to clean their keyboard. ⌨️✨</sub>

</div>
