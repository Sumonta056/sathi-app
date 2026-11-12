import Foundation

extension Engine {
    var lateStillOnItAt: Date? {
        guard let p = data.live.tracker.prompt, p.kind == .stillOnIt,
              trackerRuntime.lateShownFor != p.shownAt else { return nil }
        return p.shownAt.addingTimeInterval(Timing.lateAnswer)
    }

    func showStillOnItLate(_ n: Date) {
        guard let at = lateStillOnItAt, n >= at, let p = data.live.tracker.prompt,
              trackerRuntime.shownPrompt == .stillOnIt else { return }
        trackerRuntime.lateShownFor = p.shownAt
        presenter.showTrackerPrompt(.stillOnIt)
    }

    func logAskedEvent(_ e: CalendarEventInfo) {
        let n = clock.now.wholeSecond
        let start = e.start.wholeSecond
        let end = max(start, e.end.wholeSecond)
        let span = DateInterval(start: start, end: min(end, max(start, n)))
        if end > n {
            if let r = data.live.tracker.running, r.start > start { endRunningActivity(at: start) }
            logEvent(e, at: start)
        } else {
            cutRunning(around: span)
            storeEndedEvent(e, from: start, to: end)
        }
        makeRoom(for: span)
    }

    private func cutRunning(around span: DateInterval) {
        guard var r = data.live.tracker.running, r.start < span.end else { return }
        if r.start < span.start {
            endRunningActivity(at: span.start)
            r.id = ActivityID()
        }
        r.start = span.end
        r.lastAnswer = max(r.lastAnswer, span.end)
        r.confirmedUntil = max(r.confirmedUntil, span.end)
        data.live.tracker.running = r
    }

    private func storeEndedEvent(_ e: CalendarEventInfo, from start: Date, to end: Date) {
        let pick = eventCategory(e)
        if let added = pick.added { addActivityCategory(added.name, colorHex: added.colorHex) }
        let text = eventDraft(e, category: pick.name, from: start).text
        storeActivity(Activity(kind: .event, text: text, category: pick.name, start: start, end: end, sourceEventID: e.id))
    }

    private func makeRoom(for span: DateInterval) {
        for item in storedActivities(on: span.start) where item.start < span.end && item.end > span.start {
            if item.kind == .away {
                trackerRuntime.awayItems.removeAll { $0 == item.id }
                removeStoredActivity(item.id)
                for piece in SpanCut.cut(item.interval, removing: [span]) {
                    storeActivity(Activity(kind: .away, text: item.text, start: piece.start, end: piece.end, awayPlace: item.awayPlace))
                }
            } else if item.kind == .work {
                cutWork(item, around: span)
            }
        }
    }

    private func cutWork(_ item: Activity, around span: DateInterval) {
        removeStoredActivity(item.id)
        let pieces = SpanCut.cut(item.interval, removing: [span])
        guard let first = pieces.first else { return calendarActivityDeleted(item) }
        var kept = item
        kept.start = first.start
        kept.end = first.end
        storeActivity(calendarActivityEdited(from: item, to: kept))
        for piece in pieces.dropFirst() {
            var rest = item
            rest.id = ActivityID()
            rest.eventID = nil
            rest.start = piece.start
            rest.end = piece.end
            storeActivity(savingToCalendar(rest))
        }
    }
}
