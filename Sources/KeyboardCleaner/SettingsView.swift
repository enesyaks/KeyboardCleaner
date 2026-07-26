import AppKit
import Carbon.HIToolbox
import SwiftUI

struct SettingsView: View {
    @Bindable var state: AppState
    var onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRecordingShortcut = false
    @State private var recorderMonitor: Any?
    @State private var shortcutError: String?

    private var ink: Color {
        colorScheme == .dark ? Color(hex: 0xE8EEF0) : SettingsTheme.ink
    }

    private var settings: AppSettings { state.settings }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)

            Divider().opacity(0.35)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    launchSection
                    emergencySection
                    accessibilitySection
                }
                .padding(18)
            }
        }
        .frame(width: 320)
        .background(SettingsAtmosphere())
        .onAppear {
            state.settings.refreshLaunchAtLoginStatus()
            state.refreshTrust()
            state.syncBlockerSettings()
        }
        .onDisappear { stopRecording() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(ink.opacity(0.06)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink)
                Text("Launch & shortcuts")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.opacity(0.45))
            }

            Spacer()
        }
    }

    // MARK: - Launch

    private var launchSection: some View {
        settingsCard(title: "General", icon: "power") {
            Toggle(isOn: Binding(
                get: { settings.launchAtLogin },
                set: { settings.launchAtLogin = $0 }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Launch at login")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink)
                    Text("Start KeyboardCleaner when you log in")
                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                        .foregroundStyle(ink.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .tint(SettingsTheme.accent)

            if let error = settings.launchAtLoginError {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(SettingsTheme.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Emergency

    private var emergencySection: some View {
        settingsCard(title: "Emergency unlock", icon: "keyboard") {
            Toggle(isOn: Binding(
                get: { settings.emergencyUnlockEnabled },
                set: { settings.emergencyUnlockEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable shortcut")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink)
                    Text("Unlock instantly while the keyboard is locked")
                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                        .foregroundStyle(ink.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .tint(SettingsTheme.accent)
            .disabled(state.isLocked)

            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcut")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.opacity(0.45))

                Button {
                    if isRecordingShortcut {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    HStack {
                        Text(isRecordingShortcut ? "Press new shortcut…" : settings.emergencyShortcut.spacedDisplayString)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(isRecordingShortcut ? SettingsTheme.accent : ink)
                            .contentTransition(.opacity)

                        Spacer()

                        Image(systemName: isRecordingShortcut ? "record.circle" : "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isRecordingShortcut ? SettingsTheme.lock : ink.opacity(0.35))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(ink.opacity(isRecordingShortcut ? 0.08 : 0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isRecordingShortcut ? SettingsTheme.accent.opacity(0.55) : ink.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!settings.emergencyUnlockEnabled || state.isLocked)

                Text("Include at least one modifier (⌃ ⌥ ⇧ ⌘).")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(ink.opacity(0.4))

                if let shortcutError {
                    Text(shortcutError)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SettingsTheme.danger)
                }

                Button("Reset to default") {
                    settings.resetEmergencyShortcut()
                    shortcutError = nil
                    stopRecording()
                }
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(SettingsTheme.accent)
                .buttonStyle(.plain)
                .disabled(state.isLocked)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        settingsCard(title: "Permissions", icon: "hand.raised.fill") {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Accessibility")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink)
                    Text(state.isTrusted ? "Granted" : "Required to lock the keyboard")
                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                        .foregroundStyle(state.isTrusted ? SettingsTheme.accent : ink.opacity(0.45))
                }

                Spacer()

                Button("Open") {
                    state.openAccessibilitySettings()
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(ink.opacity(0.4))

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ink.opacity(0.04))
        )
    }

    // MARK: - Recording

    private func startRecording() {
        shortcutError = nil
        isRecordingShortcut = true
        stopRecordingMonitorOnly()

        recorderMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                DispatchQueue.main.async { stopRecording() }
                return nil
            }

            guard let chord = KeyChord.from(event: event) else {
                DispatchQueue.main.async {
                    shortcutError = "Add a modifier key, then press a letter or number."
                }
                return nil
            }

            DispatchQueue.main.async {
                settings.emergencyShortcut = chord
                shortcutError = nil
                stopRecording()
            }
            return nil
        }
    }

    private func stopRecording() {
        isRecordingShortcut = false
        stopRecordingMonitorOnly()
    }

    private func stopRecordingMonitorOnly() {
        if let recorderMonitor {
            NSEvent.removeMonitor(recorderMonitor)
            self.recorderMonitor = nil
        }
    }
}

// MARK: - Local theme

private enum SettingsTheme {
    static let ink = Color(hex: 0x14242C)
    static let accent = Color(hex: 0x1B8A78)
    static let lock = Color(hex: 0xE07A3D)
    static let warn = Color(hex: 0xC9892E)
    static let danger = Color(hex: 0xC4473A)
}

private struct SettingsAtmosphere: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color(hex: 0x1A2428) : Color(hex: 0xF3F7F6))
            Circle()
                .fill(SettingsTheme.accent.opacity(scheme == .dark ? 0.18 : 0.16))
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: -80, y: -60)
        }
        .ignoresSafeArea()
    }
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
