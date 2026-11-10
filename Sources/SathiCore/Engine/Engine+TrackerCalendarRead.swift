import Foundation

extension Engine {
    var readsCalendarEvents: Bool { trackerPrefs.readsEvents && !trackerPrefs.readCalendarIDs.isEmpty }

    var trackerEventDeadlines: [Date] {
        let n = clock.now
        let rt = trackerCalendarRuntime
        var list = [rt.noteUntil].compactMap { $0 }
        if readsCalendarEvents {
            let after = max(n, rt.checkedUntil ?? n)
            if let next = rt.events
                .first(where: { EventRules.isTimed($0) && $0.start > after && trackerHours.isInside($0.start) }) { list.append(next.start) }
        }
        return list.filter { $0 > n }
    }

    func unloggedRunningEvent() -> CalendarEventInfo? {
        guard readsCalendarEvents else { return nil }
        let n = clock.now
        return usableEvents(trackerCalendarRuntime.events, near: n).first {
            $0.start <= n && n < $0.end && !isDismissed($0) && !isLogged($0)
        }
    }

    func refreshEventsIfDue(_ n: Date) {
        guard readsCalendarEvents else {
            if trackerCalendarRuntime.readAt != nil || trackerCalendarRuntime.checkedUntil != nil {
                trackerCalendarRuntime.events = []
                trackerCalendarRuntime.readAt = nil
                trackerCalendarRuntime.checkedUntil = nil
            }
            return
        }
        guard eventReadIsDue(n) else { return }
        let start = calendar.startOfDay(for: n)
        let ids = trackerPrefs.readCalendarIDs
        trackerCalendarRuntime.events = calendarWriter.events(from: start, to: calendar.nextDay(after: start), calendarIDs: ids)
            .sorted { $0.start < $1.start }
        trackerCalendarRuntime.calendars = calendarWriter.readableCalendars()
        trackerCalendarRuntime.readAt = n
        trackerCalendarRuntime.readKey = ids
    }

    func usableEvents(_ events: [CalendarEventInfo], near day: Date) -> [CalendarEventInfo] {
        let items = activityStore.month(MonthKey(day, calendar: calendar)).items
        var written = Set(items.compactMap(\.eventID))
        if let id = timeBlock?.savedEventID { written.insert(id) }
        return EventRules.usable(events, hours: trackerHours, written: written, items: items)
    }

    func isLogged(_ e: CalendarEventInfo) -> Bool {
        if let r = data.live.tracker.running, r.sourceEventID == e.id, r.start >= e.start.wholeSecond, r.start < e.end {
            return true
        }
        return EventRules.isLogged(e, in: storedActivities(on: e.start))
    }

    func isDismissed(_ e: CalendarEventInfo) -> Bool {
        trackerCalendarRuntime.dismissed.contains(EventRules.key(e))
    }

    func dismissEvent(_ e: CalendarEventInfo) {
        trackerCalendarRuntime.dismissed.insert(EventRules.key(e))
    }

    func cachedEvent(_ id: String, at start: Date? = nil) -> CalendarEventInfo? {
        let n = clock.now
        return trackerCalendarRuntime.events.first { e in
            guard e.id == id else { return false }
            guard let start else { return e.start <= n && n < e.end }
            return e.start.wholeSecond == start.wholeSecond
        }
    }

    func calendarTitle(of e: CalendarEventInfo) -> String? {
        trackerCalendarRuntime.calendars.first { $0.id == e.calendarID }?.title
    }

    func eventCategory(_ e: CalendarEventInfo) -> EventCategoryPick {
        EventCategoryRule.pick(for: e, prefs: trackerPrefs, calendars: trackerCalendarRuntime.calendars)
    }

    private func eventReadIsDue(_ n: Date) -> Bool {
        let rt = trackerCalendarRuntime
        guard let at = rt.readAt, rt.readKey == trackerPrefs.readCalendarIDs, calendar.isDate(at, inSameDayAs: n) else {
            return true
        }
        var marks: [Date] = [trackerHours.hours(on: n).start]
        if let next = rt.events.first(where: { $0.start > at }) { marks.append(next.start) }
        if let r = data.live.tracker.running { marks += [r.start, r.askAt] }
        if let w = trackerRuntime.whatNowAt { marks.append(w) }
        return marks.contains { $0 > at && $0 <= n }
    }
}
