import AppKit
import SathiCore
import SwiftUI

@MainActor
package final class UIController: ReminderPresenter {
    package weak var engine: Engine?

    var bubbles: [HabitID: NSPanel] = [:]
    var sessions: [HabitID: NSPanel] = [:]
    var corner: [NSPanel] = []
    var quickPanels: [UUID: NSPanel] = [:]
    var cornerScreen: NSScreen?
    var celebration: NSPanel?
    var note: NSPanel?
    var daySummaryPanel: NSPanel?
    var blockStartPanel: NSPanel?
    var blockStartReturnApp: NSRunningApplication?
    var quickAddPanel: NSPanel?
    var quickAddReturnApp: NSRunningApplication?
    var blockPanels: [BlockPanel: NSPanel] = [:]
    var noteTask: Task<Void, Never>?
    var trackerPromptPanel: NSPanel?
    var trackerPromptKind: PromptKind?
    var trackerPromptShown: PromptState?
    var trackerPromptModel: ActivityPromptModel?
    var trackerReturnApp: NSRunningApplication?
    var trackerPromptHasKeys = false
    var trackerCenters: [ObjectIdentifier: NSPoint] = [:]
    var trackerNotePanel: NSPanel?
    var trackerNoteTask: Task<Void, Never>?
    var trackerEndOfDayPanel: NSPanel?
    var trackerResizeTokens: [ObjectIdentifier: NSObjectProtocol] = [:]
    var trackerMoveToken: NSObjectProtocol?
    private var locks: [NSWindow] = []
    var mainWindow: NSWindow?
    var mainRoute: MainRoute?
    let mainCloseWatcher = WindowCloseWatcher()
    var mainWindowShown: (NSWindow) -> Void = UIController.bringToFront
    var mainWindowClosed: () -> Void = UIController.backToMenuBar

    package init() {
        mainCloseWatcher.onClose = { [weak self] in self?.mainWillClose() }
    }

    package func showBubble(_ id: HabitID, _ level: Level) {
        closeBubble(id)
        bubbles[id] = bubblePanel(id, level)
    }

    private func bubblePanel(_ id: HabitID, _ level: Level) -> NSPanel? {
        switch id {
        case .water:
            return focusedBubble(id, level)
        case .reading:
            return engine?.usesCorner(id) == true ? presentCorner(ReadingInvite(level: level)) : focusedBubble(id, level)
        case .meditation:
            return presentCorner(BubbleView(id: id, level: level))
        case .gym:
            return presentCorner(GymInvite(level: level))
        }
    }

    private func focusedBubble(_ id: HabitID, _ level: Level) -> NSPanel? {
        guard let h = hosting(BubbleView(id: id, level: level)) else { return nil }
        let p = presentTopRight(h, level: .statusBar)
        if locks.isEmpty { p.makeKey() }
        return p
    }

    package func closeBubble(_ id: HabitID) {
        dismiss(bubbles.removeValue(forKey: id))
    }

    package func showSession(_ id: HabitID) {
        closeSession(id)
        if engine?.usesCorner(id) == true {
            sessions[id] = presentCorner(cornerSessionView(id))
            return
        }
        guard let h = hosting(sessionView(id)) else { return }
        sessions[id] = presentCentered(h, level: .floating)
    }

    @ViewBuilder
    private func sessionView(_ id: HabitID) -> some View {
        switch id {
        case .meditation: BreatheView()
        case .water, .reading, .gym: SessionView(id: id)
        }
    }

    package func closeSession(_ id: HabitID) {
        dismiss(sessions.removeValue(forKey: id))
    }

    package func showCelebration() {
        closeCelebration()
        guard let engine, let h = hosting(CelebrateView()) else { return }
        celebration = celebrationPanel(h, engine)
    }

    package func closeCelebration() {
        dismiss(celebration)
        celebration = nil
    }

    package func showLock(_ id: HabitID) {
        presentLocks(LockView(id: id))
    }

    func presentLocks(_ primary: some View) {
        closeLock()
        guard let engine else { return }
        for (i, screen) in NSScreen.screens.enumerated() {
            let content = i == 0 ? AnyView(primary) : AnyView(LockShade())
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

    func hosting(_ view: some View) -> FirstClickHostingView<AnyView>? {
        guard let engine else { return nil }
        let root = AnyView(view.environmentObject(engine).environment(\.colorScheme, .light))
        let h = FirstClickHostingView(rootView: root)
        let size = h.fittingSize
        h.sizingOptions = []
        h.setFrameSize(size)
        return h
    }
}
