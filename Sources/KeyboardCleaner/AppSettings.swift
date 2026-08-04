import AppKit
import Carbon.HIToolbox
import Foundation

/// Persisted preferences for launch-at-login and emergency unlock shortcut.
@Observable
final class AppSettings {
    private enum Keys {
        static let launchAtLogin = "kc.launchAtLogin"
        static let emergencyKeyCode = "kc.emergency.keyCode"
        static let emergencyControl = "kc.emergency.control"
        static let emergencyOption = "kc.emergency.option"
        static let emergencyShift = "kc.emergency.shift"
        static let emergencyCommand = "kc.emergency.command"
        static let emergencyEnabled = "kc.emergency.enabled"
        static let showOverlay = "kc.showOverlay"
        static let feedbackEnabled = "kc.feedbackEnabled"
        static let lockTrackpadWhileCleaning = "kc.lockTrackpadWhileCleaning"
        static let bossKeyEnabled = "kc.boss.enabled"
        static let bossKeyCode = "kc.boss.keyCode"
        static let bossControl = "kc.boss.control"
        static let bossOption = "kc.boss.option"
        static let bossShift = "kc.boss.shift"
        static let bossCommand = "kc.boss.command"
        static let bossStyle = "kc.boss.style"
    }

    private var isApplyingLaunchPreference = false

    var launchAtLogin: Bool {
        didSet {
            guard !isApplyingLaunchPreference, launchAtLogin != oldValue else { return }
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    var launchAtLoginError: String?

    var emergencyUnlockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(emergencyUnlockEnabled, forKey: Keys.emergencyEnabled)
            NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
        }
    }

    var emergencyShortcut: KeyChord {
        didSet { persistShortcut() }
    }

    /// Dim the screen and show a large "locked" badge while the keyboard is locked.
    var showLockOverlay: Bool {
        didSet {
            UserDefaults.standard.set(showLockOverlay, forKey: Keys.showOverlay)
            NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
        }
    }

    /// Play a sound + haptic cue when locking and unlocking.
    var feedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(feedbackEnabled, forKey: Keys.feedbackEnabled)
        }
    }

    /// In Cleaning mode, also block the mouse / trackpad (wipe the whole surface).
    /// The emergency shortcut stays the way out. Off by default.
    var lockTrackpadWhileCleaning: Bool {
        didSet {
            UserDefaults.standard.set(lockTrackpadWhileCleaning, forKey: Keys.lockTrackpadWhileCleaning)
        }
    }

    /// "Boss key" — a global shortcut that instantly hides the whole screen.
    var bossKeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(bossKeyEnabled, forKey: Keys.bossKeyEnabled)
            NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
        }
    }

    var bossKeyShortcut: KeyChord {
        didSet { persistBossShortcut() }
    }

    /// How the boss screen looks: plain black, or a decoy screensaver.
    var bossScreenStyle: BossStyle {
        didSet {
            UserDefaults.standard.set(bossScreenStyle.rawValue, forKey: Keys.bossStyle)
            NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let systemLogin = LaunchAtLogin.isEnabled

        let keyCode = UInt16(
            defaults.object(forKey: Keys.emergencyKeyCode) as? Int
                ?? Int(kVK_ANSI_K)
        )
        let shortcut = KeyChord(
            keyCode: keyCode,
            control: defaults.object(forKey: Keys.emergencyControl) as? Bool ?? true,
            option: defaults.object(forKey: Keys.emergencyOption) as? Bool ?? true,
            shift: defaults.object(forKey: Keys.emergencyShift) as? Bool ?? true,
            command: defaults.object(forKey: Keys.emergencyCommand) as? Bool ?? true
        )

        launchAtLogin = systemLogin
        launchAtLoginError = nil
        emergencyUnlockEnabled = defaults.object(forKey: Keys.emergencyEnabled) as? Bool ?? true
        emergencyShortcut = shortcut
        showLockOverlay = defaults.object(forKey: Keys.showOverlay) as? Bool ?? true
        feedbackEnabled = defaults.object(forKey: Keys.feedbackEnabled) as? Bool ?? true
        lockTrackpadWhileCleaning = defaults.object(forKey: Keys.lockTrackpadWhileCleaning) as? Bool ?? false

        bossKeyEnabled = defaults.object(forKey: Keys.bossKeyEnabled) as? Bool ?? true
        if let bossCode = defaults.object(forKey: Keys.bossKeyCode) as? Int {
            bossKeyShortcut = KeyChord(
                keyCode: UInt16(bossCode),
                control: defaults.bool(forKey: Keys.bossControl),
                option: defaults.bool(forKey: Keys.bossOption),
                shift: defaults.bool(forKey: Keys.bossShift),
                command: defaults.bool(forKey: Keys.bossCommand)
            )
        } else {
            bossKeyShortcut = .bossDefault
        }
        bossScreenStyle = BossStyle(rawValue: defaults.string(forKey: Keys.bossStyle) ?? "") ?? .blackout
        isApplyingLaunchPreference = false

        defaults.set(systemLogin, forKey: Keys.launchAtLogin)
    }

    func resetEmergencyShortcut() {
        emergencyShortcut = .default
        emergencyUnlockEnabled = true
    }

    func refreshLaunchAtLoginStatus() {
        let enabled = LaunchAtLogin.isEnabled
        guard enabled != launchAtLogin else { return }
        isApplyingLaunchPreference = true
        launchAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.launchAtLogin)
        isApplyingLaunchPreference = false
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        let result = LaunchAtLogin.setEnabled(enabled)
        launchAtLoginError = result.errorDescription
        if result.isEnabled != enabled {
            isApplyingLaunchPreference = true
            launchAtLogin = result.isEnabled
            UserDefaults.standard.set(result.isEnabled, forKey: Keys.launchAtLogin)
            isApplyingLaunchPreference = false
        }
        NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
    }

    private func persistShortcut() {
        let defaults = UserDefaults.standard
        defaults.set(Int(emergencyShortcut.keyCode), forKey: Keys.emergencyKeyCode)
        defaults.set(emergencyShortcut.control, forKey: Keys.emergencyControl)
        defaults.set(emergencyShortcut.option, forKey: Keys.emergencyOption)
        defaults.set(emergencyShortcut.shift, forKey: Keys.emergencyShift)
        defaults.set(emergencyShortcut.command, forKey: Keys.emergencyCommand)
        NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
    }

    private func persistBossShortcut() {
        let defaults = UserDefaults.standard
        defaults.set(Int(bossKeyShortcut.keyCode), forKey: Keys.bossKeyCode)
        defaults.set(bossKeyShortcut.control, forKey: Keys.bossControl)
        defaults.set(bossKeyShortcut.option, forKey: Keys.bossOption)
        defaults.set(bossKeyShortcut.shift, forKey: Keys.bossShift)
        defaults.set(bossKeyShortcut.command, forKey: Keys.bossCommand)
        NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
    }
}

struct KeyChord: Equatable, Sendable {
    var keyCode: UInt16
    var control: Bool
    var option: Bool
    var shift: Bool
    var command: Bool

    static let `default` = KeyChord(
        keyCode: UInt16(kVK_ANSI_K),
        control: true,
        option: true,
        shift: true,
        command: true
    )

    /// Default "boss key" / panic-hide shortcut: ⌥⌘.
    static let bossDefault = KeyChord(
        keyCode: UInt16(kVK_ANSI_Period),
        control: false,
        option: true,
        shift: false,
        command: true
    )

    var hasModifier: Bool {
        control || option || shift || command
    }

    var isValid: Bool {
        hasModifier
    }

    var displayString: String {
        var parts: [String] = []
        if control { parts.append("⌃") }
        if option { parts.append("⌥") }
        if shift { parts.append("⇧") }
        if command { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined()
    }

    var spacedDisplayString: String {
        var parts: [String] = []
        if control { parts.append("⌃") }
        if option { parts.append("⌥") }
        if shift { parts.append("⇧") }
        if command { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined(separator: " ")
    }

    static func keyName(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Tab: return "⇥"
        case kVK_Escape: return "Esc"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Grave: return "`"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        default: return "Key\(keyCode)"
        }
    }

    static func from(event: NSEvent) -> KeyChord? {
        let keyCode = UInt16(event.keyCode)
        if [kVK_Shift, kVK_RightShift, kVK_Control, kVK_RightControl,
            kVK_Option, kVK_RightOption, kVK_Command, kVK_RightCommand,
            kVK_Function, kVK_CapsLock].contains(Int(keyCode)) {
            return nil
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chord = KeyChord(
            keyCode: keyCode,
            control: flags.contains(.control),
            option: flags.contains(.option),
            shift: flags.contains(.shift),
            command: flags.contains(.command)
        )
        return chord.isValid ? chord : nil
    }
}
