import Foundation

extension Engine {
    var isAwayForEvents: Bool {
        data.live.tracker.awaySince != nil && data.live.tracker.awayCause != .onBreak
    }

    var eventAskWaits: Bool {
        isAwayForEvents || isAnyLockShowing || trackerRuntime.screenLocked || trackerRuntime.asleep
    }

    var eventLogNeedsAsk: Bool {
        hasOtherPrompt || pausedUntil != nil || timeBlock?.isRunning == true || trackerSessionRuns
    }

    private var hasOtherPrompt: Bool {
        guard let p = data.live.tracker.prompt else { return false }
        switch p.kind {
        case .whatNow: return p.switchFrom != nil || trackerRuntime.promptByUser
        case .stillOnIt: return !p.todoIDs.isEmpty
        case .center, .welcomeBack, .eventAsk, .todoDue: return true
        }
    }

    func askEventFirst(_ e: CalendarEventInfo) {
        let n = clock.now
        if let old = eventAskEvent(), old.id != e.id { queueEventAsk(old) }
        queueEventAsk(e)
        guard !eventAskWaits else { return }
        if let p = data.live.tracker.prompt, p.kind != .eventAsk { holdPrompt(p) }
        setTrackerPrompt(PromptState(kind: .eventAsk, shownAt: n, askTime: e.start, eventID: e.id))
    }

    func askPendingEventAgain(_ n: Date) {
        guard !isAwayForEvents else { return }
        if eventAskWaits { logWaitedEvents(until: n) }
        let asks = trackerCalendarRuntime.pendingAsks.filter { canAskEvent($0, at: n) }
        trackerCalendarRuntime.pendingAsks = asks
        guard let e = trackerCalendarRuntime.pendingAsks.first else { return }
        let p = data.live.tracker.prompt
        guard p?.kind != .eventAsk, !eventAskWaits else { return }
        if let p {
            guard !trackerRuntime.promptByUser else { return }
            holdPrompt(p)
        }
        setTrackerPrompt(PromptState(kind: .eventAsk, shownAt: n, askTime: e.start, eventID: e.id))
    }

    func restoreHeldPrompt() {
        guard let held = trackerCalendarRuntime.heldPrompt, data.live.tracker.prompt == nil,
              trackerCalendarRuntime.pendingAsks.isEmpty else { return }
        trackerCalendarRuntime.heldPrompt = nil
        setTrackerPrompt(held, byUser: trackerCalendarRuntime.heldByUser)
    }

    @discardableResult
    func logWaitedEvents(until end: Date) -> [Activity] {
        guard readsCalendarEvents else { return [] }
        let queue = trackerCalendarRuntime.pendingAsks
        let over = queue.filter { $0.end <= end && !isDismissed($0) && !isLogged($0) }
        trackerCalendarRuntime.pendingAsks = queue.filter { $0.end > end }
        if let id = data.live.tracker.prompt?.eventID, data.live.tracker.prompt?.kind == .eventAsk,
           over.contains(where: { $0.id == id }) { clearTrackerPrompt(keepsHeld: true) }
        over.forEach(logAskedEvent)
        return over.compactMap { e in
            storedActivities(on: e.start).first { $0.kind == .event && $0.sourceEventID == e.id && $0.start == e.start.wholeSecond }
        }
    }

    func dropEventAsk(_ id: String?) {
        trackerCalendarRuntime.pendingAsks.removeAll { $0.id == id }
    }

    private func queueEventAsk(_ e: CalendarEventInfo) {
        guard !trackerCalendarRuntime.pendingAsks.contains(where: { $0.id == e.id && $0.start == e.start }) else { return }
        trackerCalendarRuntime.pendingAsks.append(e)
        trackerCalendarRuntime.pendingAsks.sort { $0.start < $1.start }
    }

    private func holdPrompt(_ p: PromptState) {
        guard trackerCalendarRuntime.heldPrompt == nil else { return }
        trackerCalendarRuntime.heldPrompt = p
        trackerCalendarRuntime.heldByUser = trackerRuntime.promptByUser
    }

    private func canAskEvent(_ e: CalendarEventInfo, at n: Date) -> Bool {
        readsCalendarEvents && n < e.end && !isLogged(e) && !isDismissed(e)
    }
}
