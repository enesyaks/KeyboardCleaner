import Foundation
import Observation

@Observable
final class AppState {
    static let onboardingKey = "kc.hasCompletedOnboarding"

    var isLocked = false
    var activeMode: LockMode = .cleaning
    var isTrusted = AccessibilityManager.isTrusted
    var lockError: String?
    var sessionStartedAt: Date?
    var elapsedSeconds: Int = 0
    var hasCompletedOnboarding: Bool
    var settings = AppSettings()

    private var timer: Timer?
    private let overlay = LockOverlayController()

    static var needsOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: onboardingKey)
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        syncBlockerSettings()
        KeyboardBlocker.shared.onEmergencyUnlock = { [weak self] in
            self?.unlock()
        }
        refreshTrust()

        NotificationCenter.default.addObserver(
            forName: .keyboardCleanerPreferencesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.settings.refreshLaunchAtLoginStatus()
            self?.syncBlockerSettings()
            self?.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
            self?.refreshTrust()
            self?.syncOverlay()
        }
    }

    func syncBlockerSettings() {
        KeyboardBlocker.shared.emergencyShortcut = settings.emergencyShortcut
        KeyboardBlocker.shared.emergencyUnlockEnabled = settings.emergencyUnlockEnabled
    }

    /// Reconcile the overlay with the current lock state and preference,
    /// so toggling the setting takes effect immediately, even mid-session.
    func syncOverlay() {
        guard isLocked, settings.showLockOverlay else {
            overlay.hide()
            return
        }
        overlay.show(state: self, mode: activeMode)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
    }

    func refreshTrust() {
        isTrusted = AccessibilityManager.isTrusted
    }

    func requestPermission() {
        AccessibilityManager.requestTrust(prompt: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshTrust()
        }
    }

    func openAccessibilitySettings() {
        AccessibilityManager.openSystemSettings()
    }

    @discardableResult
    func lock(mode: LockMode = .cleaning) -> Bool {
        refreshTrust()
        syncBlockerSettings()
        guard isTrusted else {
            lockError = "Accessibility permission required. Grant access first."
            return false
        }

        KeyboardBlocker.shared.blocksPointer = mode.blocksPointer
        guard KeyboardBlocker.shared.start() else {
            lockError = "Couldn’t start keyboard lock. Quit and reopen the app, then try again."
            return false
        }

        activeMode = mode
        isLocked = true
        lockError = nil
        sessionStartedAt = Date()
        elapsedSeconds = 0
        startTimer()
        if settings.feedbackEnabled { Feedback.lock() }
        if settings.showLockOverlay { overlay.show(state: self, mode: mode) }
        return true
    }

    func unlock() {
        let wasLocked = isLocked
        KeyboardBlocker.shared.stop()
        KeyboardBlocker.shared.blocksPointer = false
        overlay.hide()
        isLocked = false
        stopTimer()
        sessionStartedAt = nil
        if wasLocked, settings.feedbackEnabled { Feedback.unlock() }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartedAt else { return }
            self.elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var emergencyShortcutLabel: String {
        guard settings.emergencyUnlockEnabled else { return "Emergency unlock off" }
        return "Emergency unlock  \(settings.emergencyShortcut.spacedDisplayString)"
    }
}
