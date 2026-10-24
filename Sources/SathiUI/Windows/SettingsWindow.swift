import AppKit
import SathiCore
import SwiftUI

@MainActor
enum SettingsWindow {
    static func make(engine: Engine, closeWatcher: SettingsWindowDelegate) -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(origin: .zero, size: UIMetrics.settingsSize),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "Sathi Settings"
        w.appearance = NSAppearance(named: .darkAqua)
        w.titlebarAppearsTransparent = true
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

@MainActor
final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}

    func windowWillClose(_: Notification) {
        onClose()
    }
}
