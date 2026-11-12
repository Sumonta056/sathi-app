import Foundation

package enum ActivityPromptBuilder {
    private typealias Copy = Copywriter

    package static func screen(_ s: TrackerPromptState) -> ActivityPromptScreen {
        switch PromptReason(s.kind) {
        case .ask: return ask(s)
        case .shortcut: return shortcut(s)
        case .ends: return ends(s)
        case .back: return back(s)
        case .event: return event(s)
        }
    }

    private static func ask(_ s: TrackerPromptState) -> ActivityPromptScreen {
        var p = ActivityPromptScreen(
            reason: .ask, tag: Copy.activityPromptAskTag, timeText: Copy.trackerClock(s.shownAt, calendar: s.calendar),
            title: Copy.trackerWhatAreYouDoingNow, message: askMessage(s), startLabel: Copy.trackerStart, skip: .skip
        )
        p.keep = s.resume.map { .continueLast($0.text) }
        p.card = lastCard(s)
        if p.card != nil { p.message = Copy.activityPromptContinueOrStart }
        p.startedChoices = startedChoices(s)
        return p
    }

    private static func askMessage(_ s: TrackerPromptState) -> String {
        if let done = s.doneAt, let r = s.running { return Copy.activityPromptNothingEnded(r.text, at: done, calendar: s.calendar) }
        guard let last = s.lastEnded else { return Copy.activityPromptNothingRuns }
        if s.resume != nil { return Copy.activityPromptEnded(last.text, at: last.end, calendar: s.calendar) }
        return Copy.activityPromptNothingEnded(last.text, at: last.end, calendar: s.calendar)
    }

    private static func shortcut(_ s: TrackerPromptState) -> ActivityPromptScreen {
        let r = s.running
        var p = ActivityPromptScreen(
            reason: .shortcut, tag: Copy.activityPromptShortcutTag(s.shortcut), timeText: Copy.trackerClock(s.now, calendar: s.calendar),
            title: r == nil ? Copy.trackerWhatAreYouDoingNow : Copy.activityPromptSwitchTitle,
            message: r == nil ? Copy.activityPromptNothingRuns : Copy.activityPromptKeepItOrSwitch,
            startLabel: r == nil ? Copy.trackerStart : Copy.trackerSwitch, skip: .close
        )
        p.keep = r.map { .keep($0.text) }
        p.card = r.map { runningCard($0, now: s.now, calendar: s.calendar) }
        p.startedChoices = startedChoices(s)
        return p
    }

    private static func ends(_ s: TrackerPromptState) -> ActivityPromptScreen {
        let r = s.running
        let end = r.flatMap { r in r.expectedLength.interval.map { r.start.addingTimeInterval($0) } }
        let ended = end.map { s.now >= $0 } ?? false
        var p = ActivityPromptScreen(
            reason: .ends, tag: ended ? Copy.activityPromptEndedTag : Copy.activityPromptStillTag,
            timeText: endsTime(r, end: end, calendar: s.calendar),
            title: r.map { Copy.activityPromptStillTitle($0.text) } ?? Copy.trackerWhatAreYouDoingNow,
            message: endsMessage(s), startLabel: Copy.trackerSwitch, skip: .skip
        )
        if let r {
            p.keep = s.isLate ? .stillOnLate : .keepGoing(s.askEveryMinutes)
            p.card = runningCard(r, now: s.now, calendar: s.calendar)
        }
        p.startedChoices = startedChoices(s)
        return p
    }

    private static func endsTime(_ r: RunningActivity?, end: Date?, calendar: Calendar) -> String {
        guard let r else { return "" }
        guard let end else { return Copy.activityPromptUntilNow(r.start, calendar: calendar) }
        return Copy.trackerSpan(r.start, end, calendar: calendar)
    }

    private static func endsMessage(_ s: TrackerPromptState) -> String {
        if let waited = s.waitedMinutes { return Copy.trackerWaited(waited) }
        guard let r = s.running else { return Copy.activityPromptNothingRuns }
        return Copy.activityPromptKeepOrSwitch(minutes: minutes(from: r.start, to: s.now))
    }

    private static func back(_ s: TrackerPromptState) -> ActivityPromptScreen {
        var p = ActivityPromptScreen(
            reason: .back, tag: Copy.activityPromptBackTag, timeText: s.away.map { Copy.activityPromptAway($0, calendar: s.calendar) } ?? "",
            title: Copy.trackerWhatAreYouDoingNow, message: backMessage(s), startLabel: Copy.trackerStart, skip: .close
        )
        p.showsWhere = true
        p.showsIWasHere = s.away?.fromIdle == true
        p.keep = s.lastActivity.map { .backTo($0.text) }
        p.card = backCard(s, detail: s.stoppedByAway == nil ? "" : p.message)
        if p.card != nil, let away = s.away {
            p.title = Copy.activityPromptWelcomeTitle
            p.message = Copy.activityPromptAwayFor(minutes: minutes(from: away.start, to: away.end))
        }
        p.startedChoices = startedChoices(s)
        return p
    }

    private static func backMessage(_ s: TrackerPromptState) -> String {
        guard let away = s.away else { return Copy.activityPromptNothingRuns }
        guard let text = s.stoppedByAway else { return Copy.activityPromptAwayFor(minutes: minutes(from: away.start, to: away.end)) }
        return Copy.activityPromptStopped(text, at: away.start, cause: away.cause, calendar: s.calendar)
    }

    private static func event(_ s: TrackerPromptState) -> ActivityPromptScreen {
        let e = s.event
        let calendarTitle = s.eventCalendarTitle ?? ""
        var p = ActivityPromptScreen(
            reason: .event, tag: Copy.activityPromptEventTag,
            timeText: e.map { Copy.trackerSpan($0.start, $0.end, calendar: s.calendar) } ?? "",
            title: Copy.activityPromptEventTitle(e?.title ?? s.draft.text),
            message: e.map { Copy.activityPromptEvent($0, calendarTitle: calendarTitle, calendar: s.calendar) } ?? "",
            startLabel: Copy.activityPromptLogIt, skip: .answerNo
        )
        p.fixedStart = e?.start
        p.calendarNote = Copy.activityPromptEventCalendar(calendarTitle)
        return p
    }

    private static func startedChoices(_ s: TrackerPromptState) -> [Date] {
        s.switchTimes.count > 1 ? s.switchTimes : []
    }

    private static func minutes(from start: Date, to end: Date) -> Int {
        max(0, Int(end.timeIntervalSince(start) / Timing.minute))
    }
}
