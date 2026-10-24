import AppKit
import SathiCore
import SwiftUI

@MainActor
package final class UIController: ReminderPresenter {
    package weak var engine: Engine?

    var bubble: NSPanel?
    var session: NSPanel?
    var celebration: NSPanel?
    var note: NSPanel?
    var noteTask: Task<Void, Never>?
    private var locks: [NSWindow] = []
    private var settings: NSWindow?
    private let settingsCloseWatcher = SettingsWindowDelegate()

    package init() {
        settingsCloseWatcher.onClose = { [weak self] in self?.settingsWillClose() }
    }

    package func showBubble(_ id: HabitID, _ level: Level) {
        closeBubble()
        closeNote()
        bubble = bubblePanel(id, level)
    }

    private func bubblePanel(_ id: HabitID, _ level: Level) -> NSPanel? {
        switch id {
        case .water:
            return focusedBubble(id, level)
        case .reading:
            return engine?.usesCorner(id) == true ? presentCorner(ReadingInvite(level: level)) : focusedBubble(id, level)
        case .meditation:
            return presentCorner(BubbleView(id: id, level: level))
        }
    }

    private func focusedBubble(_ id: HabitID, _ level: Level) -> NSPanel? {
        guard let h = hosting(BubbleView(id: id, level: level)) else { return nil }
        let p = presentTopRight(h, level: .statusBar)
        p.makeKey()
        return p
    }

    package func closeBubble() {
        bubble?.orderOut(nil)
        bubble = nil
    }

    package func showSession() {
        closeSession()
        closeNote()
        guard let id = engine?.sessionHabit else { return }
        if engine?.usesCorner(id) == true {
            session = presentCorner(ReadingTimerPill())
            return
        }
        guard let h = hosting(sessionView(id)) else { return }
        session = presentCentered(h, level: .floating)
    }

    @ViewBuilder
    private func sessionView(_ id: HabitID) -> some View {
        switch id {
        case .meditation: BreatheView()
        case .water, .reading: SessionView()
        }
    }

    package func closeSession() {
        session?.orderOut(nil)
        session = nil
    }

    package func showCelebration() {
        closeCelebration()
        closeNote()
        guard let engine, let h = hosting(CelebrateView()) else { return }
        celebration = celebrationPanel(h, engine)
    }

    package func closeCelebration() {
        celebration?.orderOut(nil)
        celebration = nil
    }

    package func showLock(_ id: HabitID) {
        closeLock()
        closeNote()
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
            settings = SettingsWindow.make(engine: engine, closeWatcher: settingsCloseWatcher)
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }

    private func settingsWillClose() {
        settings?.contentView = nil
        settings = nil
    }

    func hosting(_ view: some View) -> FirstClickHostingView<AnyView>? {
        guard let engine else { return nil }
        let root = AnyView(view.environmentObject(engine).environment(\.colorScheme, .light))
        let h = FirstClickHostingView(rootView: root)
        h.sizingOptions = []
        h.setFrameSize(h.fittingSize)
        return h
    }
}
