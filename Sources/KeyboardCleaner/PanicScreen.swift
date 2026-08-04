import AppKit
import Carbon.HIToolbox
import CoreGraphics
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

        if style == .blur {
            // Frost each open window and leave the desktop sharp. If nothing is
            // open, fall back to a full-screen frost so the key always does something.
            let perWindow = makeWindowBlurPanels()
            windows = perWindow.isEmpty ? makeFullScreenPanels() : perWindow
        } else {
            windows = makeFullScreenPanels()
        }

        for window in windows { window.orderFrontRegardless() }
        // No hint on the decoy screensaver — it must not look "hidden".
        if style != .screensaver { presentHint() }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKeyAndOrderFront(nil)

        // Esc reveals. (The global hotkey toggles independently.)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.hide()
            }
            return nil
        }
    }

    /// One opaque (black / screensaver) or transparent (full-screen blur) window
    /// per display.
    private func makeFullScreenPanels() -> [NSWindow] {
        NSScreen.screens.map { screen in
            let window = PanicWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = !style.isTransparent
            window.backgroundColor = style.isTransparent ? .clear : .black
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PanicView(style: style, shortcut: shortcutLabel))
            window.setFrame(screen.frame, display: true)
            return window
        }
    }

    /// A frosted panel over each open app window; the desktop between stays sharp.
    private func makeWindowBlurPanels() -> [NSWindow] {
        let ownName = ProcessInfo.processInfo.processName
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var panels: [NSWindow] = []
        for info in list {
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  (info[kCGWindowAlpha as String] as? Double ?? 0) > 0.1,
                  (info[kCGWindowOwnerName as String] as? String) != ownName,
                  let boundsDict = info[kCGWindowBounds as String],
                  let cg = CGRect(dictionaryRepresentation: boundsDict as! CFDictionary),
                  cg.width > 80, cg.height > 80
            else { continue }

            // Quartz bounds (top-left origin, y down) → Cocoa frame (bottom-left, y up).
            let frame = NSRect(x: cg.minX, y: primaryHeight - cg.maxY, width: cg.width, height: cg.height)

            let panel = PanicWindow(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isReleasedWhenClosed = false

            let effect = NSVisualEffectView()
            effect.material = .fullScreenUI
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.isEmphasized = true
            effect.wantsLayer = true
            effect.layer?.cornerRadius = 12
            effect.layer?.masksToBounds = true
            let tint = NSView()
            tint.wantsLayer = true
            tint.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.12).cgColor
            tint.frame = effect.bounds
            tint.autoresizingMask = [.width, .height]
            effect.addSubview(tint)

            panel.contentView = effect
            panel.setFrame(frame, display: true)
            panels.append(panel)
        }
        return panels
    }

    /// A small fading "how to reveal" hint at the bottom of the main screen.
    private func presentHint() {
        guard let primary = NSScreen.screens.first else { return }
        let text = shortcutLabel.isEmpty ? "Press Esc to reveal" : "Press \(shortcutLabel) or Esc to reveal"
        let size = NSSize(width: 380, height: 40)
        let origin = NSPoint(x: primary.frame.midX - size.width / 2, y: primary.frame.minY + 72)

        let hint = PanicWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        hint.isOpaque = false
        hint.backgroundColor = .clear
        hint.hasShadow = false
        hint.level = .screenSaver
        hint.ignoresMouseEvents = true
        hint.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hint.isReleasedWhenClosed = false
        hint.contentView = NSHostingView(rootView: RevealHint(text: text))
        windows.append(hint)
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
    case blur
    case blackout
    case screensaver

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blur: "Blur"
        case .blackout: "Black"
        case .screensaver: "Decoy"
        }
    }

    /// Blur needs a transparent window so it can frost what's behind it.
    var isTransparent: Bool { self == .blur }
}

private struct PanicView: View {
    let style: BossStyle
    let shortcut: String

    var body: some View {
        switch style {
        case .blur: BlurView(shortcut: shortcut)
        case .blackout: BlackoutView(shortcut: shortcut)
        case .screensaver: BounceScreensaver()
        }
    }
}

/// Frosts every window behind it (behind-window vibrancy) so the screen is
/// unreadable but still clearly "there" — no screen-recording permission needed.
private struct BlurView: View {
    let shortcut: String

    var body: some View {
        ZStack {
            VisualEffectBlur().ignoresSafeArea()
            Color.black.opacity(0.18).ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .fullScreenUI
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// Plain black — looks like the screen is simply off.
private struct BlackoutView: View {
    let shortcut: String
    var body: some View { Color.black.ignoresSafeArea() }
}

/// The floating "how to reveal" hint that fades out shortly after appearing.
private struct RevealHint: View {
    let text: String
    @State private var visible = true

    var body: some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(.black.opacity(0.55)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(visible ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    withAnimation(.easeInOut(duration: 1.1)) { visible = false }
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
