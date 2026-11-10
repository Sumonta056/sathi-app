import Foundation

extension Engine {
    package var recentActivities: [RecentActivity] {
        let key = MonthKey(clock.now, calendar: calendar)
        let items = activityStore.month(key.previous).items + activityStore.month(key).items
        return RecentList.recents(items)
    }

    package func trackerPromptState(_ kind: PromptKind) -> TrackerPromptState? {
        guard let p = data.live.tracker.prompt, p.kind == kind else { return nil }
        let n = clock.now
        var s = TrackerPromptState(kind: kind, shownAt: p.shownAt, now: n, draft: freshDraft())
        s.running = data.live.tracker.running
        s.lastActivity = data.live.tracker.lastActivity
        s.resume = p.resume
        s.recents = recentActivities
        s.categories = activityCategories
        s.calendars = calendarChoices()
        s.calendar = calendar
        s.askEveryMinutes = trackerPrefs.askEveryMinutes
        if let from = p.switchFrom { s.switchTimes = SwitchTimes.chips(from: from, to: n, calendar: calendar) }
        if kind == .stillOnIt { s.waitedMinutes = AskTime.waitedMinutes(shownAt: p.shownAt, now: n) }
        if kind == .welcomeBack {
            s.away = trackerRuntime.lastAway
            s.loggedWhileAway = trackerRuntime.loggedWhileAway
        }
        if kind == .whatNow || kind == .center { s.runningEvent = unloggedRunningEvent() }
        fillEventAsk(&s)
        s.actions = promptActions()
        return s
    }

    package func trackerEndOfDayState() -> TrackerEndOfDayState? {
        guard trackerRuntime.endOfDayShowing else { return nil }
        let today = DayKey(clock.now, calendar: calendar)
        var s = TrackerEndOfDayState(day: activityDay(today), categories: activityCategories)
        s.calendar = calendar
        s.openReport = { [weak self] in self?.openActivityReport(today) }
        s.close = { [weak self] in self?.closeTrackerEndOfDay() }
        return s
    }

    func freshDraft() -> ActivityDraft {
        let p = trackerPrefs
        return ActivityDraft(
            text: "",
            category: p.defaultCategory,
            length: p.usualLength,
            calendarID: p.calendarOnByDefault ? p.defaultCalendarID : nil,
            quiet: p.quietByDefault && p.usualLength.interval != nil
        )
    }

    private func promptActions() -> TrackerPromptActions {
        var a = TrackerPromptActions()
        a.start = { [weak self] draft, at in self?.startActivity(draft, switchAt: at) }
        a.skip = { [weak self] at in self?.skipTrackerPrompt(switchAt: at) }
        a.stillOn = { [weak self] minutes in self?.stillOnIt(minutes: minutes) }
        a.stillOnLate = { [weak self] in self?.stillOnItLate() }
        a.done = { [weak self] in self?.doneActivity() }
        a.continueLast = { [weak self] at in self?.continueActivity(switchAt: at) }
        a.backToLast = { [weak self] in self?.backToLastActivity() }
        a.iWasHere = { [weak self] in self?.iWasHere() }
        a.pickPlace = { [weak self] place in self?.setAwayPlace(place) }
        a.notAttending = { [weak self] id in self?.notAttendingEvent(id) }
        a.answerEvent = { [weak self] yes in self?.answerEventAsk(yes) }
        a.pickEventCategory = { [weak self] name in self?.setEventCategory(name) }
        a.close = { [weak self] in self?.closeTrackerPrompt() }
        return a
    }
}
