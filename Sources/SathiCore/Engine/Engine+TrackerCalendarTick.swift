import Foundation

extension Engine {
    func tickTrackerEvents() {
        let n = clock.now
        if let until = trackerCalendarRuntime.noteUntil, n >= until { closeEventNote() }
        refreshEventsIfDue(n)
        if readsCalendarEvents { handleEventStarts(n) }
        askPendingEventAgain(n)
        restoreHeldPrompt()
        openWhatNowAtEventEnd(n)
        showStillOnItLate(n)
    }

    func logEvent(_ e: CalendarEventInfo, at start: Date) {
        let n = clock.now.wholeSecond
        let from = max(data.live.tracker.running?.start ?? start, start.wholeSecond)
        endRunningOnInterrupt(at: from)
        let pick = eventCategory(e)
        if let added = pick.added { addActivityCategory(added.name, colorHex: added.colorHex) }
        beginActivity(eventDraft(e, category: pick.name, from: from), kind: .event, at: from)
        let end = max(from, e.end.wholeSecond)
        data.live.tracker.running?.askAt = max(end, n)
        data.live.tracker.running?.confirmedUntil = end
        trackerRuntime.whatNowAt = nil
        if let kind = data.live.tracker.prompt?.kind, kind == .whatNow || kind == .stillOnIt || kind == .eventAsk {
            clearTrackerPrompt(keepsHeld: true)
        }
        if let kind = trackerCalendarRuntime.heldPrompt?.kind, kind == .whatNow || kind == .stillOnIt {
            trackerCalendarRuntime.heldPrompt = nil
        }
        storesChanged()
    }

    func eventDraft(_ e: CalendarEventInfo, category: String?, from start: Date) -> ActivityDraft {
        let seconds = max(Timing.minute, e.end.timeIntervalSince(start))
        return ActivityDraft(
            text: ActivityText.clean(e.title) ?? calendarTitle(of: e) ?? e.id,
            category: category,
            length: .minutes(Int((seconds / Timing.minute).rounded(.up))),
            sourceEventID: e.id
        )
    }

    func showEventNote(_ note: TrackerNote) {
        if trackerCalendarRuntime.note != nil { presenter.closeTrackerNote() }
        trackerCalendarRuntime.note = note
        trackerCalendarRuntime.noteUntil = clock.now.wholeSecond.addingTimeInterval(Timing.eventNoteShow)
        presenter.showTrackerNote(note)
        objectWillChange.send()
    }

    func closeEventNote() {
        guard trackerCalendarRuntime.note != nil else { return }
        presenter.closeTrackerNote()
        trackerCalendarRuntime.note = nil
        trackerCalendarRuntime.noteUntil = nil
        trackerCalendarRuntime.undo = nil
        objectWillChange.send()
    }

    private func handleEventStarts(_ n: Date) {
        guard let from = trackerCalendarRuntime.checkedUntil else {
            trackerCalendarRuntime.checkedUntil = n
            return
        }
        trackerCalendarRuntime.checkedUntil = max(from, n)
        guard trackerCalendarRuntime.events.contains(where: { $0.start > from && $0.start <= n }), !isAwayForEvents
        else { return }
        let starting = usableEvents(trackerCalendarRuntime.events, near: n).filter {
            $0.start > from && $0.start <= n && n < $0.end && !isDismissed($0) && !isLogged($0)
        }
        starting.forEach(handleEventStart)
    }

    private func handleEventStart(_ e: CalendarEventInfo) {
        if let r = data.live.tracker.running, let source = r.sourceEventID {
            guard source != e.id, runningEventEnd(r) <= e.start else {
                if source != e.id, !trackerIsQuiet { showEventNote(.alsoNow(e)) }
                return
            }
        }
        switch trackerPrefs.eventMode {
        case .logAndTell where !eventLogNeedsAsk:
            let quiet = trackerIsQuiet
            let old = data.live.tracker.running
            logEvent(e, at: e.start)
            guard !quiet else { return }
            showEventNote(.event(e))
            trackerCalendarRuntime.undo = old
        case .logAndTell, .askFirst:
            askEventFirst(e)
        }
    }

    private func runningEventEnd(_ r: RunningActivity) -> Date {
        if r.kind == .event { return r.confirmedUntil }
        guard let id = r.sourceEventID,
              let e = trackerCalendarRuntime.events.first(where: { $0.id == id && $0.start <= r.start && r.start < $0.end })
        else { return r.askAt }
        return e.end
    }

    private func openWhatNowAtEventEnd(_ n: Date) {
        let t = data.live.tracker
        guard let r = t.running, r.kind == .event, n >= r.askAt, t.prompt == nil, t.awaySince == nil,
              !trackerIsBusy, !isAnyLockShowing else { return }
        data.live.tracker.running?.lastAnswer = r.confirmedUntil
        setTrackerPrompt(PromptState(kind: .whatNow, shownAt: n, askTime: n, switchFrom: r.confirmedUntil))
    }
}
