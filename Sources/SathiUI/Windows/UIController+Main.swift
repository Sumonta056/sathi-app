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
        NSApp.setActivationPolicy(DockPolicy.policy(mainWindowOpen: true))
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    func mainWillClose() {
        mainWindow?.contentView = nil
        mainWindow = nil
        mainRoute = nil
        NSApp.setActivationPolicy(DockPolicy.policy(mainWindowOpen: false))
    }
}
