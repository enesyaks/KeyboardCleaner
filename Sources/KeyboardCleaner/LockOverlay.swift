import AppKit
import SwiftUI

/// Full-screen visual overlay shown on every display while the keyboard is locked.
/// It is purely informational: `ignoresMouseEvents` keeps the menu bar and the
/// emergency shortcut as the ways to unlock, and it sits just below the menu bar
/// level so the status item and its popover stay reachable.
final class LockOverlayController {
    private var windows: [NSWindow] = []

    var isVisible: Bool { !windows.isEmpty }

    func show(state: AppState) {
        guard windows.isEmpty else { return }
        let level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)

        for screen in NSScreen.screens {
            let hosting = NSHostingView(rootView: LockOverlayView(state: state))
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.contentView = hosting
            window.setFrame(screen.frame, display: false)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = level
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.isReleasedWhenClosed = false
            window.alphaValue = 0
            window.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                window.animator().alphaValue = 1
            }
            windows.append(window)
        }
    }

    func hide() {
        guard !windows.isEmpty else { return }
        let closing = windows
        windows.removeAll()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            for window in closing { window.animator().alphaValue = 0 }
        } completionHandler: {
            for window in closing { window.orderOut(nil) }
        }
    }
}

// MARK: - View

private struct LockOverlayView: View {
    @Bindable var state: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false

    private let lock = Color(hex: 0xE07A3D)

    var body: some View {
        ZStack {
            Color.black.opacity(scheme == .dark ? 0.44 : 0.32)

            RadialGradient(
                colors: [lock.opacity(0.22), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 560
            )

            card
        }
        .ignoresSafeArea()
        .onAppear { pulse = true }
    }

    private var card: some View {
        VStack(spacing: 22) {
            glyph

            VStack(spacing: 8) {
                Text("Keyboard locked")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Clean away — mouse and trackpad still work.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(state.formattedElapsed)
                .font(.system(size: 42, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            hint
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 44, y: 22)
    }

    private var glyph: some View {
        ZStack {
            Circle()
                .stroke(lock.opacity(0.4), lineWidth: 2)
                .frame(width: 132, height: 132)
                .scaleEffect(pulse ? 1.14 : 0.92)
                .opacity(pulse ? 0 : 0.85)
                .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .fill(lock.opacity(0.16))
                .frame(width: 104, height: 104)

            Image(systemName: "lock.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(lock)
        }
    }

    private var hint: some View {
        HStack(spacing: 8) {
            Image(systemName: state.settings.emergencyUnlockEnabled ? "keyboard" : "cursorarrow.rays")
            Text(hintText)
        }
        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(.white.opacity(0.12)))
    }

    private var hintText: String {
        if state.settings.emergencyUnlockEnabled {
            return "Press \(state.settings.emergencyShortcut.spacedDisplayString) or use the menu bar to unlock"
        }
        return "Use the menu bar icon to unlock"
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
