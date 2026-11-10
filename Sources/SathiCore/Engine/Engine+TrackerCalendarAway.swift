import Foundation

extension Engine {
    func logEventsWhileAway(from start: Date, to end: Date) -> [Activity] {
        guard readsCalendarEvents, end > start else { return [] }
        trackerCalendarRuntime.checkedUntil = max(trackerCalendarRuntime.checkedUntil ?? end, end)
        var found: [CalendarEventInfo] = []
        for part in trackerHours.clip(DateInterval(start: start, end: end)) {
            let read = calendarWriter.events(
                from: part.start,
                to: part.end.addingTimeInterval(Timing.minute),
                calendarIDs: trackerPrefs.readCalendarIDs
            )
            found += usableEvents(read, near: part.start).filter {
                $0.start >= part.start && $0.start <= part.end && !isDismissed($0) && !isLogged($0)
            }
        }
        let final = !trackerRuntime.screenLocked && !trackerRuntime.asleep
        if trackerCalendarRuntime.calendars.isEmpty, !found.isEmpty {
            trackerCalendarRuntime.calendars = calendarWriter.readableCalendars()
        }
        let logged = EventRules.firstStays(found).map { logAwayEvent($0, until: end, final: final) }
        let earlier = storedActivities(on: start).filter { $0.kind == .event && $0.end > start && $0.start < end }
        cutAwayItems((logged + earlier).map(\.interval))
        return logged
    }

    func turnLoggedEventIntoAway(_ id: String) -> Bool {
        let rows = trackerRuntime.loggedWhileAway.filter { $0.sourceEventID == id }
        guard !rows.isEmpty else { return false }
        let n = clock.now.wholeSecond
        for row in rows {
            var span = row.interval
            if let r = data.live.tracker.running, r.id == row.id {
                data.live.tracker.running = nil
                span = DateInterval(start: r.start, end: max(r.start, n))
            } else {
                removeStoredActivity(row.id)
            }
            let place = trackerRuntime.lastAway?.place
            let away = Activity(kind: .away, text: Copywriter.trackerAwayText(place), start: span.start, end: span.end, awayPlace: place)
            storeActivity(away)
            if away.length >= Timing.activityMinimum { trackerRuntime.awayItems.append(away.id) }
        }
        trackerRuntime.loggedWhileAway.removeAll { $0.sourceEventID == id }
        objectWillChange.send()
        return true
    }

    private func logAwayEvent(_ e: CalendarEventInfo, until end: Date, final: Bool) -> Activity {
        if trackerRuntime.endedByAway?.sourceEventID == e.id { trackerRuntime.endedByAway = nil }
        let pick = eventCategory(e)
        if let added = pick.added { addActivityCategory(added.name, colorHex: added.colorHex) }
        let draft = eventDraft(e, category: pick.name, from: e.start)
        guard e.end > end, final else {
            let item = Activity(
                kind: .event, text: draft.text, category: draft.category, start: e.start, end: e.end, sourceEventID: e.id
            )
            storeActivity(item)
            return item
        }
        beginActivity(draft, kind: .event, at: e.start)
        data.live.tracker.running?.askAt = e.end.wholeSecond
        data.live.tracker.running?.confirmedUntil = e.end.wholeSecond
        return data.live.tracker.running?.activity(until: end) ?? Activity(kind: .event, text: draft.text, start: e.start, end: end)
    }

    private func cutAwayItems(_ spans: [DateInterval]) {
        guard !spans.isEmpty else { return }
        var ids: [ActivityID] = []
        for id in trackerRuntime.awayItems {
            guard let item = removeStoredActivity(id) else { continue }
            for piece in SpanCut.cut(item.interval, removing: spans) {
                let away = Activity(kind: .away, text: item.text, start: piece.start, end: piece.end, awayPlace: item.awayPlace)
                guard away.length >= Timing.activityMinimum else { continue }
                storeActivity(away)
                ids.append(away.id)
            }
        }
        trackerRuntime.awayItems = ids
    }
}
