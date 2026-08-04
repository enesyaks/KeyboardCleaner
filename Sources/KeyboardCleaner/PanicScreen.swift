import AppKit
import Carbon.HIToolbox
import SwiftUI

/// "Boss key" — instantly covers every display with an opaque black screen so
/// someone behind you can't see what's on screen. Toggle with the global
/// hotkey; dismiss with the hotkey again or Esc. While shown, keystrokes are
/// swallowed so nothing leaks to the app underneath.
final class PanicScreenController {
    private var windows: [NSWindow] = []
    private var keyMonitor: Any?

    /// Shown in the reveal hint (e.g. "⌥ ⌘ .").
    var shortcutLabel = ""

    /// What the hidden screen looks like.
    var style: BossStyle = .blackout

    var isShowing: Bool { !windows.isEmpty }

    func toggle() {
        isShowing ? hide() : show()
    }

    func show() {
        guard windows.isEmpty else { return }

        for screen in NSScreen.screens {
            let window = PanicWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PanicView(style: style, shortcut: shortcutLabel))
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKeyAndOrderFront(nil)

        // Swallow every key while hidden so nothing reaches the app underneath;
        // Esc reveals. (The global hotkey toggles independently.)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.hide()
            }
            return nil
        }
    }

    func hide() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }
}

/// Borderless windows can't become key by default; the panic screen must, so it
/// captures keystrokes instead of leaking them to whatever is behind it.
final class PanicWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// How the boss screen looks while hidden.
enum BossStyle: String, CaseIterable, Identifiable {
    case blackout
    case screensaver

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blackout: "Black screen"
        case .screensaver: "Screensaver"
        }
    }
}

private struct PanicView: View {
    let style: BossStyle
    let shortcut: String

    var body: some View {
        switch style {
        case .blackout: BlackoutView(shortcut: shortcut)
        case .screensaver: BounceScreensaver()
        }
    }
}

/// Plain black. A tiny reveal hint fades out so the screen looks simply off.
private struct BlackoutView: View {
    let shortcut: String
    @State private var showHint = true

    var body: some View {
        ZStack {
            Color.black
            if showHint {
                Text(shortcut.isEmpty ? "Press Esc to reveal" : "Press \(shortcut) or Esc to reveal")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.18))
                    .padding(.bottom, 60)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 1.1)) { showHint = false }
            }
        }
    }
}

/// A tongue-in-cheek bouncing "logo" screensaver — an innocuous decoy that
/// hides your screen behind the classic "will it hit the corner?" gag.
private struct BounceScreensaver: View {
    @State private var start = Date()

    private let logoW: CGFloat = 240
    private let logoH: CGFloat = 104
    private let speed: CGFloat = 190
    private let palette: [Color] = [
        Color(lockHex: 0xE07A3D), Color(lockHex: 0xE86B9E), Color(lockHex: 0x6B5CE0),
        Color(lockHex: 0x2E9E8F), Color(lockHex: 0x1B8A78), Color(lockHex: 0xC9892E)
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = CGFloat(timeline.date.timeIntervalSince(start))
                let maxX = max(geo.size.width - logoW, 1)
                let maxY = max(geo.size.height - logoH, 1)
                let dx = t * speed
                let dy = t * speed * 0.78
                let x = triangle(dx, span: maxX)
                let y = triangle(dy, span: maxY)
                let bounces = Int(dx / maxX) + Int(dy / maxY)

                logo(palette[((bounces % palette.count) + palette.count) % palette.count])
                    .position(x: x + logoW / 2, y: y + logoH / 2)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func logo(_ color: Color) -> some View {
        HStack(spacing: 12) {
            Text("🙈")
                .font(.system(size: 40))
            Text("brb")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: logoW, height: logoH)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color)
                .shadow(color: color.opacity(0.5), radius: 30)
        )
    }

    /// Triangle wave — position that bounces back and forth within `span`.
    private func triangle(_ distance: CGFloat, span: CGFloat) -> CGFloat {
        let m = distance.truncatingRemainder(dividingBy: 2 * span)
        return m < span ? m : 2 * span - m
    }
}
