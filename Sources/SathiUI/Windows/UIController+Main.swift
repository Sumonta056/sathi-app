import AppKit
import SathiCore

extension UIController {
    package func showMain(_ page: MainPage) {
        guard let engine else { return }
        var isNew = false
        if let mainRoute {
            mainRoute.page = page
        } else {
            isNew = true
            let route = MainRoute(page)
            mainRoute = route
            mainWindow = MainWindow.make(engine: engine, route: route, closeWatcher: mainCloseWatcher)
        }
        if let mainWindow {
            fillIfOpening(mainWindow, isNew: isNew)
            mainWindowShown(mainWindow)
        }
    }

    package func reopenMain() {
        guard let mainWindow else { return showMain(.today) }
        fillIfOpening(mainWindow, isNew: false)
        mainWindowShown(mainWindow)
    }

    private func fillIfOpening(_ window: NSWindow, isNew: Bool) {
        let fill = WindowFit.shouldFillOnShow(
            isNewWindow: isNew,
            isVisible: window.isVisible,
            isMiniaturized: window.isMiniaturized
        )
        if fill { fillPointerScreen(window) }
    }

    private func fillPointerScreen(_ window: NSWindow) {
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        guard !window.styleMask.contains(.fullScreen), let visible = screen?.visibleFrame else { return }
        mainCloseWatcher.lastVisibleFrame = visible
        window.setFrame(WindowFit.openFrame(visible: visible), display: true)
        mainCloseWatcher.shapeFrame = window.frame
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
