import AppKit
import SathiCore
import SwiftUI

@MainActor
package final class UIController: ReminderPresenter {
    package weak var engine: Engine?

    private var bubble: NSPanel?
    private var session: NSPanel?
    private var celebration: NSPanel?
    private var locks: [NSWindow] = []
    private var settings: NSWindow?

    private var primary: NSScreen? { NSScreen.screens.first ?? NSScreen.main }

    package init() {}

    package func showBubble(_ id: HabitID, _ level: Level) {
        closeBubble()
        guard let h = hosting(BubbleView(id: id, level: level)) else { return }
        let p = makePanel(h, level: .statusBar)
        if let vf = primary?.visibleFrame {
            let inset = UIMetrics.bubbleScreenInset
            p.setFrameOrigin(NSPoint(x: vf.maxX - h.frame.width + inset.x, y: vf.maxY - h.frame.height + inset.y))
        }
        fadeIn(p)
        p.makeKey()
        bubble = p
    }

    package func closeBubble() {
        bubble?.orderOut(nil)
        bubble = nil
    }

    package func showSession() {
        closeSession()
        guard let h = hosting(SessionView()) else { return }
        session = presentCentered(h, level: .floating)
    }

    package func closeSession() {
        session?.orderOut(nil)
        session = nil
    }

    package func showCelebration() {
        closeCelebration()
        guard let h = hosting(CelebrateView()) else { return }
        celebration = presentCentered(h, level: .statusBar)
    }

    package func closeCelebration() {
        celebration?.orderOut(nil)
        celebration = nil
    }

    package func showLock(_ id: HabitID) {
        closeLock()
        guard let engine else { return }
        for (i, screen) in NSScreen.screens.enumerated() {
            let content = i == 0 ? AnyView(LockView(id: id)) : AnyView(LockShade())
            locks.append(LockScreen.makeWindow(on: screen, content: content, engine: engine))
        }
        NSApp.activate(ignoringOtherApps: true)
        locks.first?.makeKey()
        NSApp.presentationOptions = LockScreen.presentationOptions
    }

    package func closeLock() {
        guard !locks.isEmpty else { return }
        locks.forEach { $0.orderOut(nil) }
        locks.removeAll()
        NSApp.presentationOptions = []
    }

    package func showSettings() {
        if settings == nil, let engine {
            let size = UIMetrics.settingsSize
            let w = NSWindow(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            w.title = "Sathi Settings"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: SettingsView().environmentObject(engine))
            w.center()
            settings = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }

    private func hosting(_ view: some View) -> NSHostingView<AnyView>? {
        guard let engine else { return nil }
        let root = AnyView(view.environmentObject(engine).environment(\.colorScheme, .light))
        let h = NSHostingView(rootView: root)
        h.setFrameSize(h.fittingSize)
        return h
    }

    private func makePanel(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        let p = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: content.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
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

    private func presentCentered(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        let p = makePanel(content, level: level)
        if let f = primary?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: f.midX - p.frame.width / 2, y: f.midY - p.frame.height / 2))
        }
        fadeIn(p)
        return p
    }

    private func fadeIn(_ w: NSWindow) {
        w.alphaValue = 0
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = UIMetrics.fadeDuration
            w.animator().alphaValue = 1
        }
    }
}
