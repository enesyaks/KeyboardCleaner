import AppKit

/// Subtle sound + haptic cues for lock / unlock transitions.
enum Feedback {
    static func lock() {
        NSSound(named: "Tink")?.play()
        haptic()
    }

    static func unlock() {
        NSSound(named: "Pop")?.play()
        haptic()
    }

    private static func haptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
