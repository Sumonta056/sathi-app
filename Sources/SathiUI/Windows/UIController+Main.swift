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
            placeIfOpening(mainWindow, isNew: isNew)
            mainWindowShown(mainWindow)
        }
    }

    package func reopenMain() {
        guard let mainWindow else { return showMain(.today) }
        placeIfOpening(mainWindow, isNew: false)
        mainWindowShown(mainWindow)
    }

    private func placeIfOpening(_ window: NSWindow, isNew: Bool) {
        let place = WindowFit.shouldPlaceOnShow(
            isNewWindow: isNew,
            isVisible: window.isVisible,
            isMiniaturized: window.isMiniaturized
        )
        if place { placeAtRememberedFrame(window) }
    }

    private func placeAtRememberedFrame(_ window: NSWindow) {
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        guard !window.styleMask.contains(.fullScreen), let visible = screen?.visibleFrame else { return }
        let frame = WindowFit.openFrame(
            saved: mainFrames.frame(),
            screens: NSScreen.screens.map(\.visibleFrame),
            pointer: visible,
            defaultSize: UIMetrics.mainWindowSize
        )
        mainCloseWatcher.lastVisibleFrame = Self.visibleFrame(holding: frame) ?? visible
        window.setFrame(frame, display: true)
        mainCloseWatcher.shapeFrame = window.frame
    }

    private static func visibleFrame(holding frame: CGRect) -> CGRect? {
        func area(_ r: CGRect) -> CGFloat { r.isNull ? 0 : r.width * r.height }
        return NSScreen.screens.map(\.visibleFrame)
            .filter { $0.intersects(frame) }
            .max { area($0.intersection(frame)) < area($1.intersection(frame)) }
    }

    func rememberMainFrame() {
        guard let mainWindow, !mainWindow.styleMask.contains(.fullScreen) else { return }
        mainFrames.save(mainWindow)
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
