import SwiftUI

/// The different reasons to lock input. They share the same keyboard blocker
/// but differ in framing, colour, whether the pointer is also blocked, and
/// whether the full-screen overlay stays up or briefly confirms and fades.
enum LockMode: String, CaseIterable, Identifiable {
    case cleaning
    case baby
    case movie
    case handoff

    var id: String { rawValue }

    /// Compact name for cards / captions.
    var shortTitle: String {
        switch self {
        case .cleaning: "Cleaning"
        case .baby: "Baby & Pet"
        case .movie: "Movie"
        case .handoff: "Hand-off"
        }
    }

    /// Full title for the locked state and overlay.
    var title: String {
        switch self {
        case .cleaning: "Cleaning mode"
        case .baby: "Baby & pet lock"
        case .movie: "Movie mode"
        case .handoff: "Hand-off mode"
        }
    }

    var icon: String {
        switch self {
        case .cleaning: "sparkles"
        case .baby: "teddybear.fill"
        case .movie: "film.fill"
        case .handoff: "person.2.fill"
        }
    }

    /// One-line hint shown under the Start button while unlocked.
    var pickerHint: String {
        switch self {
        case .cleaning: "Keys off, mouse stays active"
        case .baby: "Keyboard + trackpad locked, screen stays on"
        case .movie: "Blocks accidental keys while you watch"
        case .handoff: "Hand your Mac over with the keyboard locked"
        }
    }

    /// Sub-line shown inside the full-screen overlay.
    var overlaySubtitle: String {
        switch self {
        case .cleaning: "Clean away — mouse and trackpad still work."
        case .baby: "Keyboard & trackpad are locked — the show keeps playing."
        case .movie: "Keys are off — enjoy the movie."
        case .handoff: "Keyboard is locked — safe to hand over."
        }
    }

    /// Baby / pet mode also swallows mouse + trackpad so the only way out is
    /// the emergency shortcut. Other modes leave the pointer free.
    var blocksPointer: Bool { self == .baby }

    /// Cleaning keeps the overlay up the whole session; the other modes only
    /// flash it as a confirmation so it never covers what you're watching.
    var usesPersistentOverlay: Bool { self == .cleaning }

    var tint: Color {
        switch self {
        case .cleaning: Color(lockHex: 0xE07A3D)
        case .baby: Color(lockHex: 0xE86B9E)
        case .movie: Color(lockHex: 0x6B5CE0)
        case .handoff: Color(lockHex: 0x2E9E8F)
        }
    }
}

extension Color {
    /// Shared hex initializer used across the lock-mode UI.
    init(lockHex hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
