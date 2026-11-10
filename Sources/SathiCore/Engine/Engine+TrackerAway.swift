import Foundation

extension Engine {
    func beginAway(at start: Date, cause: AwayCause) {
        guard trackerPrefs.isOn else { return }
        if data.live.tracker.awaySince != nil {
            if cause == .onBreak || data.live.tracker.awayCause != .onBreak { data.live.tracker.awayCause = cause }
            return
        }
        let at = start.wholeSecond
        data.live.tracker.awaySince = at
        data.live.tracker.awayCause = cause
        trackerRuntime.endedByAway = pendingDoneAt == nil ? data.live.tracker.running : nil
        if let r = data.live.tracker.running {
            let end = cause == .onBreak ? at : AskTime.awayEnd(start: r.start, confirmedUntil: r.confirmedUntil, awayStart: at)
            endRunningOnInterrupt(at: end)
        }
        clearTrackerPrompt()
        requestTick()
    }

    func returnFromAway(at end: Date, welcomes: Bool = true) {
        guard let since = data.live.tracker.awaySince else { return }
        let back = max(since, end.wholeSecond)
        let cause = data.live.tracker.awayCause ?? .locked
        let place: AwayPlace? = cause == .onBreak ? .breakTime : nil
        data.live.tracker.awaySince = nil
        data.live.tracker.awayCause = nil
        data.live.tracker.lastInput = back
        let items = trackerHours.clip(DateInterval(start: since, end: back)).map {
            Activity(kind: .away, text: Copywriter.trackerAwayText(place), start: $0.start, end: $0.end, awayPlace: place)
        }.filter { $0.length >= Timing.activityMinimum }
        items.forEach(storeActivity)
        trackerRuntime.awayItems = items.map(\.id)
        trackerRuntime.lastAway = AwaySpan(start: since, end: back, cause: cause, place: place)
        trackerRuntime.loggedWhileAway = logEventsWhileAway(from: since, to: back)
        if welcomes, trackerHours.isInside(back) {
            setTrackerPrompt(PromptState(kind: .welcomeBack, shownAt: back, askTime: back))
        }
        requestTick()
    }

    func endBreakAway(at n: Date) {
        let held: AwayCause? = trackerRuntime.screenLocked ? .locked : trackerRuntime.asleep ? .asleep : nil
        returnFromAway(at: n, welcomes: held == nil)
        guard let held else { return }
        data.live.tracker.awaySince = n.wholeSecond
        data.live.tracker.awayCause = held
    }

    func checkIdle(_ n: Date) {
        let t = data.live.tracker
        guard !trackerSessionRuns else { return }
        if let since = t.awaySince {
            guard t.awayCause == .idle else { return }
            let input = n.addingTimeInterval(-presence.secondsSinceLastInput()).wholeSecond
            if input > since { returnFromAway(at: input) }
            return
        }
        guard let last = t.lastInput else {
            data.live.tracker.lastInput = n.wholeSecond
            return
        }
        guard n >= last.addingTimeInterval(idleLimit) else { return }
        let idle = presence.secondsSinceLastInput()
        let input = n.addingTimeInterval(-idle).wholeSecond
        if idle >= idleLimit {
            beginAway(at: input, cause: .idle)
        } else {
            data.live.tracker.lastInput = input
        }
    }

    func handlePresence(_ event: PresenceEvent) {
        let n = clock.now
        switch event {
        case .locked:
            trackerRuntime.screenLocked = true
            beginAway(at: n, cause: .locked)
        case .sleep:
            trackerRuntime.asleep = true
            beginAway(at: n, cause: .asleep)
        case .unlocked:
            trackerRuntime.screenLocked = false
            if data.live.tracker.awayCause != .onBreak { returnFromAway(at: n) }
        case .wake:
            trackerRuntime.asleep = false
            if !trackerRuntime.screenLocked, data.live.tracker.awayCause != .onBreak { returnFromAway(at: n) }
        }
    }

    func restoreAwayItem() {
        guard trackerRuntime.lastAway?.fromIdle == true else { return }
        trackerRuntime.awayItems.forEach { removeStoredActivity($0) }
        trackerRuntime.awayItems = []
        trackerRuntime.lastAway = nil
        guard var r = trackerRuntime.endedByAway else { return }
        if let old = removeStoredActivity(r.id) { calendarActivityDeleted(old) }
        let n = clock.now.wholeSecond
        r.lastAnswer = n
        r.askAt = n.addingTimeInterval(trackerAskEvery)
        r.confirmedUntil = r.askAt
        data.live.tracker.running = r
        trackerRuntime.endedByAway = nil
    }

    func pickAwayPlace(_ place: AwayPlace) {
        guard !trackerRuntime.awayItems.isEmpty else { return }
        for id in trackerRuntime.awayItems {
            guard var item = removeStoredActivity(id) else { continue }
            item.awayPlace = place
            item.text = Copywriter.trackerAwayText(place)
            storeActivity(item)
        }
        trackerRuntime.lastAway?.place = place
    }
}
