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
        guard !eventAskWaits else {
            trackerCalendarRuntime.pendingAsk = e
            return
        }
        var waiting = e
        if let p = data.live.tracker.prompt {
            if p.kind == .eventAsk {
                if let old = eventAskEvent(), old.id != e.id, canAskEvent(old, at: n) { waiting = old }
            } else {
                holdPrompt(p)
            }
        }
        setTrackerPrompt(PromptState(kind: .eventAsk, shownAt: n, askTime: e.start, eventID: e.id))
        trackerCalendarRuntime.pendingAsk = waiting
    }

    func askPendingEventAgain(_ n: Date) {
        guard let e = trackerCalendarRuntime.pendingAsk else { return }
        guard canAskEvent(e, at: n) else {
            trackerCalendarRuntime.pendingAsk = nil
            return
        }
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
              trackerCalendarRuntime.pendingAsk == nil else { return }
        trackerCalendarRuntime.heldPrompt = nil
        setTrackerPrompt(held, byUser: trackerCalendarRuntime.heldByUser)
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
