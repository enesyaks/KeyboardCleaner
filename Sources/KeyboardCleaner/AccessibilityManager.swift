import ApplicationServices
import AppKit
import Foundation

/// Erişilebilirlik izni olmadan CGEventTap klavye olaylarını yakalayamaz / engelleyemez.
enum AccessibilityManager {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Sistem Ayarları'nda izin diyaloğunu (veya paneli) açar.
    @discardableResult
    static func requestTrust(prompt: Bool = true) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    static func openSystemSettings() {
        // macOS 13+ Gizlilik & Güvenlik > Erişilebilirlik
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
