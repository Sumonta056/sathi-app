import SwiftUI
import AppKit

/// Borderless panel that can take clicks and keyboard focus without activating the app.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Full-screen lock window.
final class LockWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Owns every window Sathi shows outside the menu bar.
@MainActor
final class UIController {
    weak var engine: Engine?

    private var bubble: NSPanel?
    private var session: NSPanel?
    private var celebration: NSPanel?
    private var locks: [NSWindow] = []
    private var settings: NSWindow?

    private var model: Engine { engine ?? Engine.shared }
    private var primary: NSScreen? { NSScreen.screens.first ?? NSScreen.main }

    private func hosting<V: View>(_ view: V, scheme: ColorScheme = .light) -> NSHostingView<AnyView> {
        let root = AnyView(view.environmentObject(model).environment(\.colorScheme, scheme))
        let h = NSHostingView(rootView: root)
        h.setFrameSize(h.fittingSize)
        return h
    }

    private func makePanel(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        let p = FloatingPanel(contentRect: NSRect(origin: .zero, size: content.frame.size),
                              styleMask: [.borderless, .nonactivatingPanel],
                              backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = level
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.contentView = content
        return p
    }

    private func fadeIn(_ w: NSWindow) {
        w.alphaValue = 0
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            w.animator().alphaValue = 1
        }
    }

    private func center(_ w: NSWindow) {
        guard let f = primary?.visibleFrame else { return }
        w.setFrameOrigin(NSPoint(x: f.midX - w.frame.width / 2, y: f.midY - w.frame.height / 2))
    }

    // MARK: Bubble (top right, under the menu bar)

    func showBubble(_ id: HabitID, _ level: Level) {
        closeBubble()
        let h = hosting(BubbleView(id: id, level: level))
        let p = makePanel(h, level: .statusBar)
        if let vf = primary?.visibleFrame {
            // The SwiftUI view has 24 pt of transparent padding for its shadow.
            p.setFrameOrigin(NSPoint(x: vf.maxX - h.frame.width + 12, y: vf.maxY - h.frame.height + 20))
        }
        fadeIn(p)
        p.makeKey()
        bubble = p
    }

    func closeBubble() {
        bubble?.orderOut(nil)
        bubble = nil
    }

    // MARK: Reading session

    func showSession() {
        closeSession()
        let h = hosting(SessionView())
        let p = makePanel(h, level: .floating)
        center(p)
        fadeIn(p)
        session = p
    }

    func closeSession() {
        session?.orderOut(nil)
        session = nil
    }

    // MARK: Celebration

    func showCelebrate() {
        closeCelebrate()
        let h = hosting(CelebrateView())
        let p = makePanel(h, level: .statusBar)
        center(p)
        fadeIn(p)
        celebration = p
    }

    func closeCelebrate() {
        celebration?.orderOut(nil)
        celebration = nil
    }

    // MARK: Lock screen (every display)

    func showLock(_ id: HabitID) {
        closeLock()
        for (i, screen) in NSScreen.screens.enumerated() {
            let w = LockWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            w.setFrame(screen.frame, display: false)
            w.level = .screenSaver
            w.isOpaque = false
            w.backgroundColor = .clear
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            w.isReleasedWhenClosed = false
            let content: AnyView = i == 0 ? AnyView(LockView(id: id)) : AnyView(LockShade())
            let h = NSHostingView(rootView: AnyView(content.environmentObject(model).environment(\.colorScheme, .dark)))
            h.frame = NSRect(origin: .zero, size: screen.frame.size)
            w.contentView = h
            w.orderFrontRegardless()
            locks.append(w)
        }
        NSApp.activate(ignoringOtherApps: true)
        locks.first?.makeKey()
        // Hide the Dock and menu bar and block Cmd-Tab while locked.
        NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableHideApplication]
    }

    func closeLock() {
        guard !locks.isEmpty else { return }
        locks.forEach { $0.orderOut(nil) }
        locks.removeAll()
        NSApp.presentationOptions = []
    }

    // MARK: Settings

    func showSettings() {
        if settings == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 680),
                             styleMask: [.titled, .closable, .miniaturizable],
                             backing: .buffered, defer: false)
            w.title = "Sathi Settings"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: SettingsView().environmentObject(model))
            w.center()
            settings = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }
}
