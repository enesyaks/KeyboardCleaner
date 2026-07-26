import ApplicationServices
import AppKit
import Foundation

/// Without Accessibility permission, the CGEventTap can't observe or block keyboard events.
enum AccessibilityManager {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Opens the permission prompt (or the Accessibility pane in System Settings).
    @discardableResult
    static func requestTrust(prompt: Bool = true) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    static func openSystemSettings() {
        // macOS 13+ Privacy & Security > Accessibility
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for string in urls {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
