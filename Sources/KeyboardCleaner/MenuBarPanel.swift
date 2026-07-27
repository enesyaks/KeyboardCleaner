import AppKit
import SwiftUI

/// Compact menu bar popover.
struct MenuBarPanel: View {
    @Bindable var state: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var route: PanelRoute = .home
    @State private var selectedMode: LockMode = .cleaning

    private enum PanelRoute: Equatable {
        case home
        case settings
    }

    private var ink: Color {
        colorScheme == .dark ? Color(hex: 0xE8EEF0) : Theme.ink
    }

    var body: some View {
        Group {
            switch route {
            case .home:
                homePanel
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .settings:
                SettingsView(state: state) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        route = .home
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: route)
        .onAppear {
            state.refreshTrust()
            state.settings.refreshLaunchAtLoginStatus()
            state.syncBlockerSettings()
        }
        .onChange(of: state.settings.emergencyShortcut) { _, _ in
            state.syncBlockerSettings()
        }
        .onChange(of: state.settings.emergencyUnlockEnabled) { _, _ in
            state.syncBlockerSettings()
        }
    }

    private var homePanel: some View {
        ZStack {
            Atmosphere()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                Divider()
                    .opacity(0.35)

                Group {
                    if !state.isTrusted {
                        permissionContent
                    } else {
                        lockContent
                    }
                }
                .padding(18)
                .animation(.spring(response: 0.4, dampingFraction: 0.88), value: state.isLocked)
                .animation(.easeInOut(duration: 0.25), value: state.isTrusted)

                Divider()
                    .opacity(0.35)

                footer
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(headerBadgeColor.opacity(0.16))
                    .frame(width: 36, height: 36)

                Image(systemName: state.isLocked ? state.activeMode.icon : "keyboard.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(headerBadgeColor)
                    .contentTransition(.symbolEffect(.replace))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("KeyboardCleaner")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink)

                Text(statusCaption)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(ink.opacity(0.5))
            }

            Spacer(minLength: 0)

            statusPill
        }
    }

    private var statusCaption: String {
        if !state.isTrusted { return "Setup required" }
        return state.isLocked ? "\(state.activeMode.shortTitle) • locked" : "Keyboard protection"
    }

    private var headerBadgeColor: Color {
        if !state.isTrusted { return Theme.warn }
        return state.isLocked ? state.activeMode.tint : Theme.accent
    }

    private var statusPill: some View {
        Text(pillText)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(pillForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(pillForeground.opacity(0.14)))
    }

    private var pillText: String {
        if !state.isTrusted { return "SETUP" }
        return state.isLocked ? "LOCKED" : "READY"
    }

    private var pillForeground: Color {
        if !state.isTrusted { return Theme.warn }
        return state.isLocked ? state.activeMode.tint : Theme.accent
    }

    // MARK: - Permission

    private var permissionContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Accessibility access")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(ink)

            Text("macOS needs your permission to block keyboard input. After granting access, quit and reopen the app.")
                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                .foregroundStyle(ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1.5)

            VStack(spacing: 8) {
                Button {
                    state.requestPermission()
                } label: {
                    Label("Request Access", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PanelButtonStyle(role: .primary, ink: ink))

                Button {
                    state.openAccessibilitySettings()
                } label: {
                    Label("Open System Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PanelButtonStyle(role: .secondary, ink: ink))

                Button {
                    state.refreshTrust()
                } label: {
                    Text("Check permission")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Lock

    private var lockContent: some View {
        VStack(spacing: 16) {
            if state.isLocked {
                lockedBody
            } else {
                unlockedBody
            }

            if let error = state.lockError {
                Text(error)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Unlocked — mode picker

    private var unlockedBody: some View {
        VStack(spacing: 14) {
            modeGrid

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    _ = state.lock(mode: selectedMode)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text("Start \(selectedMode.shortTitle)")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PanelButtonStyle(role: .primary, ink: ink, tint: selectedMode.tint))

            hintRow(
                icon: selectedMode.blocksPointer ? "cursorarrow.slash" : "cursorarrow.click",
                text: selectedMode.pickerHint
            )
        }
    }

    private var modeGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(LockMode.allCases) { mode in
                modeCard(mode)
            }
        }
    }

    private func modeCard(_ mode: LockMode) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                selectedMode = mode
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? mode.tint : ink.opacity(0.5))

                Text(mode.shortTitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? ink : ink.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? mode.tint.opacity(0.14) : ink.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? mode.tint.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Locked

    private var lockedBody: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                lockGlyph

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.formattedElapsed)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                        .contentTransition(.numericText())

                    Text("\(state.activeMode.title) · running")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(ink.opacity(0.45))
                }

                Spacer(minLength: 0)
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    state.unlock()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                    Text("Unlock")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PanelButtonStyle(role: .unlock, ink: ink, tint: state.activeMode.tint))

            lockedHint
        }
    }

    @ViewBuilder
    private var lockedHint: some View {
        if state.settings.emergencyUnlockEnabled || state.activeMode.blocksPointer {
            hintRow(
                icon: "exclamationmark.keyboard",
                text: "Emergency unlock  \(state.settings.emergencyShortcut.spacedDisplayString)"
            )
        } else {
            hintRow(icon: "exclamationmark.triangle", text: "Emergency unlock is off")
        }
    }

    private var lockGlyph: some View {
        ZStack {
            Circle()
                .fill(state.activeMode.tint.opacity(0.12))
                .frame(width: 56, height: 56)

            Circle()
                .stroke(state.activeMode.tint.opacity(0.35), lineWidth: 2)
                .frame(width: 56, height: 56)

            Image(systemName: state.activeMode.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(state.activeMode.tint)
                .symbolEffect(.pulse, options: .repeating, isActive: state.isLocked)
                .scaleEffect(state.isLocked ? 1.05 : 1)
        }
    }

    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ink.opacity(0.35))
                .frame(width: 16)

            Text(text)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(ink.opacity(0.45))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ink.opacity(0.06))
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    route = .settings
                }
            } label: {
                Text("Settings")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(FooterLinkStyle(ink: ink))

            Spacer()

            Button {
                if state.isLocked { state.unlock() }
                NSApp.terminate(nil)
            } label: {
                Text("Quit")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(FooterLinkStyle(ink: ink, destructive: true))
        }
    }
}

// MARK: - Atmosphere

private struct Atmosphere: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Theme.surfaceDark : Theme.surfaceLight)

            Circle()
                .fill(Theme.accent.opacity(scheme == .dark ? 0.22 : 0.2))
                .frame(width: 180, height: 180)
                .blur(radius: 48)
                .offset(x: -90, y: -70)

            Circle()
                .fill(Theme.lock.opacity(0.14))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: 100, y: 90)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Theme & Styles

private enum Theme {
    static let ink = Color(hex: 0x14242C)
    static let accent = Color(hex: 0x1B8A78)
    static let lock = Color(hex: 0xE07A3D)
    static let warn = Color(hex: 0xC9892E)
    static let danger = Color(hex: 0xC4473A)
    static let surfaceLight = Color(hex: 0xF3F7F6)
    static let surfaceDark = Color(hex: 0x1A2428)
}

private struct PanelButtonStyle: ButtonStyle {
    enum Role { case primary, secondary, unlock }
    var role: Role = .primary
    var ink: Color = Theme.ink
    var tint: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(background)
                    .opacity(configuration.isPressed ? 0.88 : 1)
            )
            .overlay {
                if role == .secondary {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ink.opacity(0.1), lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch role {
        case .primary, .unlock: return .white
        case .secondary: return ink.opacity(0.82)
        }
    }

    private var background: Color {
        switch role {
        case .primary, .unlock: return tint
        case .secondary: return ink.opacity(0.08)
        }
    }
}

private struct FooterLinkStyle: ButtonStyle {
    var ink: Color = Theme.ink
    var destructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .medium, design: .rounded))
            .foregroundStyle(
                (destructive ? Theme.danger : ink)
                    .opacity(configuration.isPressed ? 0.35 : (destructive ? 0.75 : 0.42))
            )
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
