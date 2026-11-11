import AppKit
import SathiUI
import Testing

@MainActor
@Suite("App menu")
struct AppMenuTests {
    private func closeItems(_ menu: NSMenu) -> [NSMenuItem] {
        menu.items.flatMap { item in
            (item.action == #selector(NSWindow.performClose(_:)) ? [item] : []) + (item.submenu.map(closeItems) ?? [])
        }
    }

    private func swiftUIMenu() -> NSMenu {
        let main = NSMenu()
        for title in ["Sathi", "Edit", "View", "Window", "Help"] {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.submenu = NSMenu(title: title)
            main.addItem(item)
        }
        return main
    }

    @Test func fileMenuHasCloseOnCommandW() throws {
        let file = AppMenu.fileMenu()
        #expect(file.title == "File")
        let submenu = try #require(file.submenu)
        let close = try #require(closeItems(submenu).first)
        #expect(close.title == "Close")
        #expect(close.keyEquivalent == "w")
        #expect(close.keyEquivalentModifierMask == .command)
    }

    @Test func installAddsFileAfterTheAppMenuAndKeepsTheOthers() {
        let main = swiftUIMenu()
        AppMenu.install(in: main)
        #expect(main.items.map(\.title) == ["Sathi", "File", "Edit", "View", "Window", "Help"])
        #expect(closeItems(main).count == 1)
    }

    @Test func installTwiceAddsCloseOnce() {
        let main = swiftUIMenu()
        AppMenu.install(in: main)
        AppMenu.install(in: main)
        #expect(closeItems(main).count == 1)
    }
}
