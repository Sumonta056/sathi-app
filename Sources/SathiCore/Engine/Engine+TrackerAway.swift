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
        let r = data.live.tracker.running
        let keeps = r.map { keepsThroughAway($0, cause: cause, at: at) } ?? false
        trackerRuntime.endedByAway = pendingDoneAt == nil && !keeps ? r : nil
        trackerRuntime.endedMergedInto = nil
        if let r, !keeps {
            let end = cause.endsAtOnce ? at : AskTime.awayEnd(start: r.start, confirmedUntil: r.confirmedUntil, awayStart: at)
            endRunningOnInterrupt(at: end, interrupt: at)
        }
        clearTrackerPrompt()
        requestTick()
    }

    func returnFromAway(at end: Date, welcomes: Bool = true) {
        guard let since = data.live.tracker.awaySince else { return }
        let back = max(since, end.wholeSecond)
        let cause = data.live.tracker.awayCause ?? .locked
        let plan = data.live.tracker.awayPlan
        let place: AwayPlace? = plan?.place ?? (cause == .onBreak ? .breakTime : nil)
        data.live.tracker.awaySince = nil
        data.live.tracker.awayCause = nil
        data.live.tracker.awayPlan = nil
        data.live.tracker.lastInput = back
        var eventSpan: DateInterval?
        if let r = data.live.tracker.running, r.kind == .buddy, trackerSessionRuns { return requestTick() }
        if let r = data.live.tracker.running, r.kind == .event {
            guard back >= r.confirmedUntil else {
                awayRows(from: since, to: min(back, r.start), place: place, name: plan?.name).forEach(storeActivity)
                return requestTick()
            }
            eventSpan = DateInterval(start: r.start, end: max(r.start, r.confirmedUntil))
            endRunningActivity(at: r.confirmedUntil)
        }
        let items = awayRows(from: since, to: back, removing: eventSpan.map { [$0] } ?? [], place: place, name: plan?.name)
        items.forEach(storeActivity)
        trackerRuntime.awayItems = items.map(\.id)
        trackerRuntime.lastAway = AwaySpan(start: since, end: back, cause: cause, place: place, placeName: plan?.name)
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
        guard !trackerActiveSessionRuns else { return }
        if let since = t.awaySince {
            guard let grace = t.awayCause?.inputGrace else { return }
            let input = n.addingTimeInterval(-presence.secondsSinceLastInput()).wholeSecond
            if input > since, input >= since.addingTimeInterval(grace) { returnFromAway(at: input) }
            return
        }
        guard let last = idleSince else {
            data.live.tracker.lastInput = n.wholeSecond
            return
        }
        guard n >= last.addingTimeInterval(idleLimit) else { return }
        let idle = presence.secondsSinceLastInput()
        let input = n.addingTimeInterval(-idle).wholeSecond
        if idle >= idleLimit {
            beginAway(at: max(input, last), cause: .idle)
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
        if let before = trackerRuntime.endedMergedInto {
            replaceStoredActivity(before.id) { calendarActivityEdited(from: $0, to: before) }
        } else if let old = removeStoredActivity(r.id) {
            calendarActivityDeleted(old)
        }
        trackerRuntime.endedMergedInto = nil
        keepTodoAsk(&r)
        let n = clock.now.wholeSecond
        r.lastAnswer = n
        r.askAt = n.addingTimeInterval(trackerAskEvery)
        r.confirmedUntil = r.askAt
        data.live.tracker.running = r
        trackerRuntime.endedByAway = nil
    }

    var offersIWasHere: Bool {
        guard let away = trackerRuntime.lastAway, away.fromIdle else { return false }
        return data.live.tracker.running.map { $0.start < away.end } ?? true
    }

    var trackerActiveSessionRuns: Bool { HabitID.allCases.contains { session($0).map { !$0.isPaused } ?? false } }

    var idleSince: Date? {
        let paused = HabitID.allCases.compactMap { session($0)?.pausedAt }.max()
        guard let last = data.live.tracker.lastInput else { return paused }
        return max(last, paused ?? last)
    }

    private func keepsThroughAway(_ r: RunningActivity, cause: AwayCause, at: Date) -> Bool {
        guard !cause.endsAtOnce, pendingDoneAt == nil else { return false }
        if r.kind == .buddy { return trackerSessionRuns }
        return r.kind == .event && at < r.confirmedUntil
    }

    private func awayRows(
        from since: Date, to back: Date, removing extra: [DateInterval] = [], place: AwayPlace?, name: String?
    ) -> [Activity] {
        guard back > since else { return [] }
        return trackerHours.clip(DateInterval(start: since, end: back))
            .flatMap { SpanCut.cut($0, removing: extra + loggedSpans(from: since, to: back)) }
            .map {
                Activity(
                    kind: .away, text: Copywriter.trackerAwayText(place, name: name),
                    start: $0.start, end: $0.end, awayPlace: place, awayPlaceName: name
                )
            }
            .filter { $0.length >= Timing.activityMinimum }
    }

    private func loggedSpans(from since: Date, to back: Date) -> [DateInterval] {
        var items = storedActivities(on: since)
        if !calendar.isDate(since, inSameDayAs: back) { items += storedActivities(on: back) }
        return items.filter { $0.kind != .away && $0.start < back && $0.end > since }.map(\.interval)
    }
}
