import AppKit
import SathiCore

@MainActor
package enum AppMenu {
    package static func fileMenu() -> NSMenuItem {
        let menu = NSMenu(title: Copywriter.mainMenuFile)
        menu.addItem(withTitle: Copywriter.mainMenuClose, action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let item = NSMenuItem(title: Copywriter.mainMenuFile, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    package static func install(in main: NSMenu?) {
        guard let main, !hasClose(main) else { return }
        main.insertItem(fileMenu(), at: min(1, main.numberOfItems))
    }

    private static func hasClose(_ menu: NSMenu) -> Bool {
        menu.items.contains { item in
            item.action == #selector(NSWindow.performClose(_:)) || item.submenu.map(hasClose) == true
        }
    }
}
