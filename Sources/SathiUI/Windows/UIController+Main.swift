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
        if let mainWindow { mainWindowShown(mainWindow) }
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
        window.makeKeyAndOrderFront(nil)
    }

    static func backToMenuBar() {
        NSApp.setActivationPolicy(DockPolicy.policy(mainWindowOpen: false))
    }
}
