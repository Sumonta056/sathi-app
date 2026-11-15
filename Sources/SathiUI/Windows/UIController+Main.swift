import AppKit
import SathiCore

extension UIController {
    package func showMain(_ page: MainPage) {
        guard let engine else { return }
        if let mainRoute {
            mainRoute.page = page
        } else {
            let route = MainRoute(page)
            mainRoute = route
            mainWindow = MainWindow.make(engine: engine, route: route, closeWatcher: mainCloseWatcher)
        }
        if let mainWindow {
            fillPointerScreen(mainWindow)
            mainWindowShown(mainWindow)
        }
    }

    package func reopenMain() {
        guard let mainWindow else { return showMain(.today) }
        fillPointerScreen(mainWindow)
        mainWindowShown(mainWindow)
    }

    private func fillPointerScreen(_ window: NSWindow) {
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        mainCloseWatcher.lastVisibleFrame = visible
        window.setFrame(WindowFit.openFrame(visible: visible), display: true)
    }

    func mainWillClose() {
        mainWindow?.contentView = nil
        mainWindow = nil
        mainRoute = nil
        mainWindowClosed()
    }

    static func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(DockPolicy.policy(mainWindowOpen: true))
        NSApp.activate(ignoringOtherApps: true)
        AppMenu.install(in: NSApp.mainMenu)
        DispatchQueue.main.async { AppMenu.install(in: NSApp.mainMenu) }
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
    }

    static func backToMenuBar() {
        NSApp.setActivationPolicy(DockPolicy.policy(mainWindowOpen: false))
    }
}
