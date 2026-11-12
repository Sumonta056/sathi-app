import AppKit
import SathiCore
@testable import SathiUI
import Testing

@Suite("Shortcut capture")
struct ShortcutCaptureTests {
    @Test func buildsAShortcutFromKeysAndModifiers() {
        let s = ShortcutCapture.shortcut(keyCode: 40, flags: [.command, .option], characters: "k")
        #expect(s == KeyShortcut(keyCode: 40, modifiers: [.command, .option], keyName: "K"))
    }

    @Test func spaceHasItsName() {
        let s = ShortcutCapture.shortcut(keyCode: 49, flags: [.control], characters: " ")
        #expect(s?.keyName == Copywriter.trackerSpaceKeyName)
    }

    @Test func noModifierIsRejected() {
        #expect(ShortcutCapture.shortcut(keyCode: 40, flags: [], characters: "k") == nil)
    }

    @Test func shiftAloneIsRejected() {
        #expect(ShortcutCapture.shortcut(keyCode: 40, flags: [.shift], characters: "K") == nil)
    }

    @Test func escapeCancels() {
        #expect(ShortcutCapture.isCancel(keyCode: ShortcutCapture.escapeKeyCode))
        #expect(!ShortcutCapture.isCancel(keyCode: 40))
    }
}
