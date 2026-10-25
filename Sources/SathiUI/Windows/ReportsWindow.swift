import AppKit
import SathiCore
import SwiftUI

@MainActor
enum ReportsWindow {
    static func make(engine: Engine, closeWatcher: WindowCloseWatcher) -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: UIMetrics.reportsSize),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Sathi Reports"
        w.appearance = NSAppearance(named: .darkAqua)
        w.titlebarAppearsTransparent = true
        w.backgroundColor = NSColor(Night.bg)
        w.isReleasedWhenClosed = false
        w.delegate = closeWatcher
        let root = ReportsView()
            .environmentObject(engine)
            .environment(\.colorScheme, .dark)
        w.contentView = NSHostingView(rootView: root)
        w.center()
        return w
    }
}
