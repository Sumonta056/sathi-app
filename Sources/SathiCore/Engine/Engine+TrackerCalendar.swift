import Foundation

extension Engine {
    package func readableCalendarChoices() -> [CalendarChoice] {
        calendarWriter.readableCalendars()
    }

    package func trackerNoteState() -> TrackerNoteState? {
        guard let note = trackerCalendarRuntime.note else { return nil }
        let e = note.event
        let r = data.live.tracker.running
        let category = r?.sourceEventID == e.id ? r?.category : eventCategory(e).name
        var s = TrackerNoteState(note: note, calendarTitle: calendarTitle(of: e), category: category)
        s.categories = activityCategories
        s.calendar = calendar
        if case .event = note { s.endedText = trackerCalendarRuntime.undo?.text }
        s.actions.undo = { [weak self] in self?.undoEventNote() }
        s.actions.notAttending = { [weak self] in self?.notAttendingEvent(e.id) }
        s.actions.pickCategory = { [weak self] name in self?.setEventCategory(name) }
        s.actions.switchToEvent = { [weak self] in self?.switchToOverlappingEvent() }
        return s
    }

    package func undoEventNote() {
        guard case let .event(e) = trackerCalendarRuntime.note else { return }
        let old = trackerCalendarRuntime.undo
        closeEventNote()
        dismissEvent(e)
        guard data.live.tracker.running?.sourceEventID == e.id else { return }
        data.live.tracker.running = nil
        if let old {
            if let item = removeStoredActivity(old.id) { calendarActivityDeleted(item) }
            data.live.tracker.running = old
            data.live.tracker.lastActivity = draft(of: old)
        }
        objectWillChange.send()
        requestTick()
    }

    package func notAttendingEvent(_ eventID: String) {
        let n = clock.now.wholeSecond
        if let e = trackerCalendarRuntime.note?.event, e.id == eventID { dismissEvent(e) }
        if trackerCalendarRuntime.note?.event.id == eventID { closeEventNote() }
        if let e = eventAskEvent(), e.id == eventID {
            dismissEvent(e)
            clearTrackerPrompt()
        }
        if let e = cachedEvent(eventID) { dismissEvent(e) }
        if let e = trackerCalendarRuntime.pendingAsk, e.id == eventID {
            dismissEvent(e)
            trackerCalendarRuntime.pendingAsk = nil
        }
        if turnLoggedEventIntoAway(eventID) {
            requestTick()
            return
        }
        if let r = data.live.tracker.running, r.sourceEventID == eventID {
            data.live.tracker.running = nil
            setTrackerPrompt(PromptState(kind: .whatNow, shownAt: n, askTime: n, switchFrom: r.start))
        }
        objectWillChange.send()
        requestTick()
    }

    package func setEventCategory(_ category: String) {
        guard activityCategories.contains(where: { $0.name == category }),
              let e = trackerCalendarRuntime.note?.event ?? eventAskEvent() else { return }
        data.prefs.tracker.eventCategoryByTitle[e.title] = category
        if data.live.tracker.running?.sourceEventID == e.id { data.live.tracker.running?.category = category }
        objectWillChange.send()
    }

    package func answerEventAsk(_ yes: Bool) {
        guard data.live.tracker.prompt?.kind == .eventAsk else { return }
        let e = eventAskEvent()
        clearTrackerPrompt()
        trackerCalendarRuntime.pendingAsk = nil
        if let e {
            if yes {
                logAskedEvent(e)
            } else {
                dismissEvent(e)
            }
        }
        requestTick()
    }

    package func switchToOverlappingEvent() {
        guard case let .alsoNow(e) = trackerCalendarRuntime.note else { return }
        closeEventNote()
        logEvent(e, at: e.start)
        requestTick()
    }

    package func fillEventAsk(_ s: inout TrackerPromptState) {
        guard s.kind == .eventAsk, let e = eventAskEvent() else { return }
        s.event = e
        s.eventCalendarTitle = calendarTitle(of: e)
        s.draft.text = e.title
        s.draft.category = eventCategory(e).name
        s.draft.sourceEventID = e.id
    }

    func eventAskEvent() -> CalendarEventInfo? {
        guard let p = data.live.tracker.prompt, p.kind == .eventAsk, let id = p.eventID else { return nil }
        if let e = trackerCalendarRuntime.pendingAsk, e.id == id, e.start.wholeSecond == p.askTime { return e }
        return cachedEvent(id, at: p.askTime)
    }
}
