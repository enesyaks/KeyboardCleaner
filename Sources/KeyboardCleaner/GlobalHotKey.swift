import Carbon.HIToolbox
import Foundation

/// A single system-wide hotkey backed by Carbon `RegisterEventHotKey`.
///
/// Unlike an `NSEvent` global monitor, this actually *consumes* the combo, so
/// it never leaks to the frontmost app, and it works while the app is a
/// background/accessory process — without needing Accessibility permission.
final class GlobalHotKey {
    var onPress: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x4B43_4C52 /* "KCLR" */, id: 1)

    /// Register (or re-register) the hotkey for the given key + modifiers.
    func update(keyCode: UInt16, control: Bool, option: Bool, shift: Bool, command: Bool) {
        unregister()
        installHandlerIfNeeded()

        var mods: UInt32 = 0
        if control { mods |= UInt32(controlKey) }
        if option { mods |= UInt32(optionKey) }
        if shift { mods |= UInt32(shiftKey) }
        if command { mods |= UInt32(cmdKey) }

        RegisterEventHotKey(
            UInt32(keyCode),
            mods,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let this = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { this.onPress?() }
                return noErr
            },
            1,
            &spec,
            selfPtr,
            &handlerRef
        )
    }

    deinit {
        unregister()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }
}
