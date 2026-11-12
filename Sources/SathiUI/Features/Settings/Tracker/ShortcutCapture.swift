import AppKit
import SathiCore

enum ShortcutCapture {
    static let escapeKeyCode = Limits.escapeKeyCode

    static func isCancel(keyCode: UInt32) -> Bool { keyCode == escapeKeyCode }

    static func shortcut(keyCode: UInt32, flags: NSEvent.ModifierFlags, characters: String?) -> KeyShortcut? {
        let modifiers = Self.modifiers(flags)
        guard !modifiers.subtracting([.shift]).isEmpty else { return nil }
        let name = Copywriter.trackerNamedKeys[keyCode] ?? characters?.uppercased() ?? ""
        guard !name.isEmpty else { return nil }
        return KeyShortcut(keyCode: keyCode, modifiers: modifiers, keyName: name)
    }

    static func modifiers(_ flags: NSEvent.ModifierFlags) -> Set<KeyModifier> {
        var set: Set<KeyModifier> = []
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.shift) { set.insert(.shift) }
        if flags.contains(.command) { set.insert(.command) }
        return set
    }
}
