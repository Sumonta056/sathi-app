import AppKit
import SathiCore
import SwiftUI

@MainActor
enum SettingsWindow {
    static func make(engine: Engine, closeWatcher: WindowCloseWatcher) -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: UIMetrics.settingsSize),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Sathi Settings"
        w.appearance = NSAppearance(named: .darkAqua)
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.backgroundColor = NSColor(Night.sidebar)
        w.isReleasedWhenClosed = false
        w.delegate = closeWatcher
        let root = SettingsView()
            .environmentObject(engine)
            .environment(\.colorScheme, .dark)
        w.contentView = NSHostingView(rootView: root)
        w.center()
        return w
    }
}
