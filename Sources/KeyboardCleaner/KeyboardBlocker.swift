import ApplicationServices
import Carbon.HIToolbox
import Foundation

/// Intercepts keyboard events via CGEventTap and swallows them while locked.
/// Mouse / trackpad stay active so the UI can unlock.
final class KeyboardBlocker {
    static let shared = KeyboardBlocker()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isBlocking = false

    /// Current emergency shortcut (read on each key event).
    var emergencyShortcut: KeyChord = .default
    var emergencyUnlockEnabled = true

    /// When true, mouse / trackpad events are swallowed too (baby / pet mode).
    /// Set this before calling `start()`; it decides the event-tap mask.
    var blocksPointer = false

    var onEmergencyUnlock: (() -> Void)?

    /// Pointer events swallowed in pointer-blocking modes. `mouseMoved` is left
    /// alone so the cursor still tracks — only clicks, drags and scrolling die.
    private static let pointerEventTypes: [CGEventType] = [
        .leftMouseDown, .leftMouseUp,
        .rightMouseDown, .rightMouseUp,
        .otherMouseDown, .otherMouseUp,
        .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
        .scrollWheel
    ]

    private init() {}

    func start() -> Bool {
        guard !isBlocking else { return true }
        guard AccessibilityManager.isTrusted else { return false }

        let systemDefined = CGEventType(rawValue: 14)!
        var mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << systemDefined.rawValue)

        if blocksPointer {
            for type in Self.pointerEventTypes {
                mask |= (1 << type.rawValue)
            }
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let blocker = Unmanaged<KeyboardBlocker>.fromOpaque(refcon).takeUnretainedValue()
                return blocker.handle(type: type, event: event)
            },
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isBlocking = true
        return true
    }

    func stop() {
        guard isBlocking else { return }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
        isBlocking = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard isBlocking else {
            return Unmanaged.passUnretained(event)
        }

        // The emergency shortcut is the only escape when the pointer is blocked,
        // so honor it even if the user turned the toggle off for that session.
        if type == .keyDown, emergencyUnlockEnabled || blocksPointer, matchesEmergencyUnlock(event) {
            DispatchQueue.main.async { [weak self] in
                self?.onEmergencyUnlock?()
            }
            return nil
        }

        if type.rawValue == 14 {
            return nil
        }

        if type == .keyDown || type == .keyUp || type == .flagsChanged {
            return nil
        }

        if blocksPointer, Self.pointerEventTypes.contains(type) {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func matchesEmergencyUnlock(_ event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == CGKeyCode(emergencyShortcut.keyCode) else { return false }

        let flags = event.flags
        if emergencyShortcut.control, !flags.contains(.maskControl) { return false }
        if emergencyShortcut.option, !flags.contains(.maskAlternate) { return false }
        if emergencyShortcut.shift, !flags.contains(.maskShift) { return false }
        if emergencyShortcut.command, !flags.contains(.maskCommand) { return false }

        // Require exact modifier set (ignore caps lock / fn / numeric pad)
        let relevant: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
        let present = flags.intersection(relevant)
        var expected: CGEventFlags = []
        if emergencyShortcut.control { expected.insert(.maskControl) }
        if emergencyShortcut.option { expected.insert(.maskAlternate) }
        if emergencyShortcut.shift { expected.insert(.maskShift) }
        if emergencyShortcut.command { expected.insert(.maskCommand) }
        return present == expected
    }
}
