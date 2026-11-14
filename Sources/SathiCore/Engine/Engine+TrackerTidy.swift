import Foundation

extension Engine {
    func mergeOldRowsOnce() {
        guard !data.prefs.tracker.mergedEventRows else { return }
        defer { activityStore.releaseUnused() }
        let keep = rowsInAwayUndo()
        var done = true
        for key in activityStore.savedMonths() {
            let month = activityStore.month(key)
            let days = StoredRowsMerge.days(month, calendar: calendar)
                .map { rows in (rows, !rows.contains { keep.contains($0.id) } && StoredRowsMerge.canMerge(rows)) }
            guard days.contains(where: \.1) else { continue }
            guard activityStore.backup(key) else {
                done = false
                continue
            }
            var items: [Activity] = []
            var changed = false
            for (rows, merges) in days {
                guard merges else {
                    items += rows
                    continue
                }
                let out = mergedRows(rows)
                if !out.complete { done = false }
                if out.rows != rows { changed = true }
                items += out.rows
            }
            if changed { activityStore.save(ActivityMonth(key: month.key, items: items)) }
        }
        if done { data.prefs.tracker.mergedEventRows = true }
    }

    private func mergedRows(_ rows: [Activity]) -> (rows: [Activity], complete: Bool) {
        var out: [Activity] = []
        var eventEnd = Date.distantPast
        var complete = true
        for row in rows {
            guard let last = out.last, ActivityMerge.canMerge(last, row) else {
                out.append(row)
                eventEnd = row.end
                continue
            }
            guard ActivityMerge.hasEvent(last), let drop = row.eventID, !drop.isEmpty else {
                if !ActivityMerge.hasEvent(last) { eventEnd = row.end }
                out[out.count - 1] = ActivityMerge.joined(last, row)
                continue
            }
            switch movedEventEnd(last, to: row.end) {
            case let .moved(moved) where calendarWriter.delete(eventID: drop):
                out[out.count - 1] = ActivityMerge.joined(moved, row)
            case let .moved(moved):
                complete = false
                if case let .moved(back) = movedEventEnd(moved, to: eventEnd) {
                    out[out.count - 1] = back
                } else {
                    out[out.count - 1] = moved
                }
                out.append(row)
            case .failed:
                complete = false
                out.append(row)
            case .cannot:
                out.append(row)
            }
            eventEnd = row.end
        }
        return (out, complete)
    }

    private enum EventMove {
        case moved(Activity)
        case failed
        case cannot
    }

    private func movedEventEnd(_ a: Activity, to end: Date) -> EventMove {
        guard let id = a.eventID, let calendarID = a.calendarID else { return .cannot }
        let draft = CalendarEventDraft(calendarID: calendarID, title: a.text, start: a.start, end: end)
        switch calendarWriter.update(eventID: id, draft: draft) {
        case let .saved(saved):
            var b = a
            if !saved.isEmpty { b.eventID = saved }
            return .moved(b)
        case .calendarMissing: return .cannot
        case .failed: return .failed
        }
    }

    private func rowsInAwayUndo() -> Set<ActivityID> {
        let away = data.live.tracker.away
        return Set(away.awayItems + away.loggedWhileAway.map(\.id) + [away.endedMergedInto?.id].compactMap { $0 })
    }
}
