import AppKit
import SathiCore
import SwiftUI

@MainActor
enum MainWindow {
    static func make(engine: Engine, route: MainRoute, closeWatcher: WindowCloseWatcher) -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: UIMetrics.mainWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Sathi"
        w.appearance = NSAppearance(named: .darkAqua)
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.backgroundColor = NSColor(Night.bg)
        w.isReleasedWhenClosed = false
        w.contentMinSize = UIMetrics.mainWindowMinSize
        w.delegate = closeWatcher
        let host = NSHostingView(rootView: MainView(route: route)
            .environmentObject(engine)
            .environment(\.colorScheme, .dark))
        host.sizingOptions = []
        w.contentView = host
        w.setContentSize(UIMetrics.mainWindowSize)
        return w
    }
}
