import AppKit
import SwiftUI

extension Notification.Name {
    static let keyboardCleanerPreferencesChanged = Notification.Name("com.enes.KeyboardCleaner.preferencesChanged")
}

@main
struct KeyboardCleanerApp: App {
    @State private var state = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(state: state)
                .onAppear {
                    state.refreshTrust()
                    state.settings.refreshLaunchAtLoginStatus()
                    state.syncBlockerSettings()
                }
        } label: {
            MenuBarLabel(
                isLocked: state.isLocked,
                isTrusted: state.isTrusted,
                elapsed: state.formattedElapsed
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let isLocked: Bool
    let isTrusted: Bool
    let elapsed: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse, options: .repeating, isActive: isLocked)

            if isLocked {
                Text(elapsed)
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
            }
        }
        .accessibilityLabel(accessibilityText)
    }

    private var iconName: String {
        if !isTrusted { return "keyboard.badge.ellipsis" }
        return isLocked ? "lock.fill" : "keyboard"
    }

    private var accessibilityText: String {
        if !isTrusted { return "KeyboardCleaner — permission needed" }
        return isLocked ? "KeyboardCleaner — locked, \(elapsed)" : "KeyboardCleaner"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if AppState.needsOnboarding {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async { [weak self] in
                self?.presentOnboarding()
            }
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if AppState.needsOnboarding {
            presentOnboarding()
            return true
        }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        KeyboardBlocker.shared.stop()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == onboardingWindow else { return }
        onboardingWindow = nil
        // Keep menu bar mode even if onboarding was dismissed via the close button
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
    }

    private func presentOnboarding() {
        if let onboardingWindow, onboardingWindow.isVisible {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let root = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: AppState.onboardingKey)
            NotificationCenter.default.post(name: .keyboardCleanerPreferencesChanged, object: nil)
            self?.onboardingWindow?.delegate = nil
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "KeyboardCleaner"
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.setContentSize(NSSize(width: 460, height: 620))
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}
