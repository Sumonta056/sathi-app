import Foundation

extension Engine {
    var trackerPrefs: TrackerPrefs { data.prefs.tracker }
    var trackerHours: TrackerHours { TrackerHours(prefs: trackerPrefs, calendar: calendar) }
    var trackerAskEvery: TimeInterval { TimeInterval(trackerPrefs.askEveryMinutes) * Timing.minute }

    func beginActivity(_ draft: ActivityDraft, kind: ActivityKind = .work, at start: Date) {
        let n = clock.now
        let every = AskTime.first(
            start: start,
            length: draft.length,
            offsetMinutes: draft.askOffsetMinutes,
            askEveryMinutes: trackerPrefs.askEveryMinutes
        )
        let end = AskTime.lengthEnd(start: start, length: draft.length, offsetMinutes: draft.askOffsetMinutes)
        let first = kind == .work && !draft.quiet ? every : end ?? every
        var r = RunningActivity(
            kind: kind,
            text: draft.text,
            category: draft.category,
            start: start,
            expectedLength: draft.length,
            askAt: max(first, n)
        )
        r.calendarID = kind == .buddy ? nil : draft.calendarID
        r.sourceEventID = draft.sourceEventID
        if draft.quiet, let span = draft.length.interval, start.addingTimeInterval(span) > n {
            r.quietUntil = start.addingTimeInterval(span).wholeSecond
        }
        data.live.tracker.running = r
        if kind != .buddy { data.live.tracker.lastActivity = draft }
    }

    var pendingDoneAt: Date? {
        guard data.live.tracker.running != nil, let p = data.live.tracker.prompt,
              p.kind == .whatNow, p.resume == nil else { return nil }
        return p.doneAt ?? p.switchFrom
    }

    @discardableResult
    func endRunningOnInterrupt(at end: Date, interrupt: Date? = nil) -> Activity? {
        endRunningActivity(at: pendingDoneAt.map { min($0, interrupt ?? end) } ?? end)
    }

    @discardableResult
    func endRunningActivity(at end: Date) -> Activity? {
        guard let r = data.live.tracker.running else { return nil }
        data.live.tracker.running = nil
        let stop = max(r.start, min(end, calendar.nextDay(after: r.start)))
        var item = r.activity(until: stop)
        guard item.length >= Timing.activityMinimum else { return nil }
        if item.kind != .buddy { item = savingToCalendar(item) }
        storeActivity(item)
        return item
    }

    func storeActivity(_ item: Activity) {
        guard item.length >= Timing.activityMinimum else { return }
        let key = MonthKey(item.start, calendar: calendar)
        var month = activityStore.month(key)
        month.items.append(item)
        month.items.sort { $0.start < $1.start }
        activityStore.save(month)
        storesChanged()
    }

    @discardableResult
    func removeStoredActivity(_ id: ActivityID) -> Activity? {
        for key in activityStore.savedMonths().reversed() {
            var month = activityStore.month(key)
            guard let i = month.items.firstIndex(where: { $0.id == id }) else { continue }
            let item = month.items.remove(at: i)
            activityStore.save(month)
            storesChanged()
            return item
        }
        return nil
    }

    func storedActivity(_ id: ActivityID) -> Activity? {
        activityStore.allActivities().first { $0.id == id }
    }

    func storedActivities(on day: Date) -> [Activity] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.nextDay(after: start)
        return activityStore.month(MonthKey(start, calendar: calendar)).items
            .filter { $0.start >= start && $0.start < end }
            .sorted { $0.start < $1.start }
    }
}
