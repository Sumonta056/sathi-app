import AppKit
import SathiCore
import SwiftUI

@MainActor
enum LockScreen {
    static let presentationOptions: NSApplication.PresentationOptions = [
        .hideDock, .hideMenuBar, .disableProcessSwitching, .disableHideApplication
    ]

    static func makeWindow(on screen: NSScreen, content: AnyView, engine: Engine) -> NSWindow {
        let w = LockWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        w.setFrame(screen.frame, display: false)
        w.level = .screenSaver
        w.isOpaque = false
        w.backgroundColor = .clear
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.isReleasedWhenClosed = false
        let root = AnyView(content.environmentObject(engine).environment(\.colorScheme, .dark))
        let h = NSHostingView(rootView: root)
        h.frame = NSRect(origin: .zero, size: screen.frame.size)
        w.contentView = h
        w.orderFrontRegardless()
        return w
    }
}
