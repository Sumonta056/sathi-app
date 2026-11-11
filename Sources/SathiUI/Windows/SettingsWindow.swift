import AppKit
import SathiCore
import SwiftUI

@MainActor
enum SettingsWindow {
    static func make(engine: Engine, tab: SettingsTab = .general, closeWatcher: WindowCloseWatcher) -> NSWindow {
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
        w.contentView = content(engine: engine, tab: tab)
        w.center()
        return w
    }

    static func content(engine: Engine, tab: SettingsTab) -> NSView {
        NSHostingView(rootView: SettingsView(tab: tab)
            .environmentObject(engine)
            .environment(\.colorScheme, .dark))
    }
}
