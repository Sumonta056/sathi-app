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
        s.doneAt = p.doneAt
        s.recents = recentActivities
        s.categories = activityCategories
        s.calendars = calendarChoices()
        s.defaultCalendarID = trackerDefaultCalendarID
        s.calendarAccess = calendarAccess
        s.calendar = calendar
        s.askEveryMinutes = trackerPrefs.askEveryMinutes
        s.shortcut = trackerPrefs.shortcut
        s.switchTimes = promptSwitchTimes(p, now: n)
        if kind == .whatNow { s.lastEnded = lastEndedActivity(before: n) }
        if kind == .stillOnIt { s.waitedMinutes = AskTime.waitedMinutes(shownAt: p.shownAt, now: n) }
        if kind == .welcomeBack {
            s.away = trackerRuntime.lastAway
            s.loggedWhileAway = trackerRuntime.loggedWhileAway
            s.stoppedByAway = trackerRuntime.endedByAway?.text
        }
        s.places = awayPlaces
        if kind == .whatNow || kind == .center { s.runningEvent = unloggedRunningEvent() }
        fillEventAsk(&s)
        fillTodos(&s, prompt: p)
        s.actions = promptActions()
        return s
    }

    package func trackerEndOfDayState() -> TrackerEndOfDayState? {
        guard trackerRuntime.endOfDayShowing else { return nil }
        let today = trackerRuntime.endOfDayDay ?? DayKey(clock.now, calendar: calendar)
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
            calendarID: p.calendarOnByDefault ? trackerDefaultCalendarID : nil,
            quiet: p.quietByDefault && p.usualLength.interval != nil
        )
    }

    var trackerDefaultCalendarID: String? {
        let ids = calendarChoices().map(\.id)
        let candidates = [trackerPrefs.defaultCalendarID, calendarWriter.defaultCalendarID()]
        return candidates.compactMap { $0 }.first(where: ids.contains) ?? ids.first
    }

    func allowTrackerCalendar() async -> TrackerCalendarInfo {
        await requestCalendarAccess()
        let allowed = calendarAccess == .allowed
        return TrackerCalendarInfo(
            access: calendarAccess,
            calendars: allowed ? calendarChoices() : [],
            defaultID: allowed ? trackerDefaultCalendarID : nil
        )
    }

    private func promptActions() -> TrackerPromptActions {
        var a = TrackerPromptActions()
        a.start = { [weak self] draft, at in self?.startActivity(draft, switchAt: at) ?? false }
        a.skip = { [weak self] at in self?.skipTrackerPrompt(switchAt: at) }
        a.stillOn = { [weak self] minutes in self?.stillOnIt(minutes: minutes) }
        a.stillOnLate = { [weak self] in self?.stillOnItLate() }
        a.done = { [weak self] in self?.doneActivity() }
        a.continueLast = { [weak self] at in self?.continueActivity(switchAt: at) }
        a.backToLast = { [weak self] in self?.backToLastActivity() }
        a.iWasHere = { [weak self] in self?.iWasHere() }
        a.pickPlace = { [weak self] place in self?.setAwayPlace(place) }
        a.pickPlaceName = { [weak self] name in self?.setAwayPlace(named: name) }
        a.goAway = { [weak self] place, name in self?.goAway(place: place, name: name) }
        a.addPlace = { [weak self] name in self?.addAwayPlace(name) }
        a.notAttending = { [weak self] id in self?.notAttendingEvent(id) }
        a.answerEvent = { [weak self] yes in self?.answerEventAsk(yes) }
        a.pickEventCategory = { [weak self] name in self?.setEventCategory(name) }
        a.allowCalendar = { [weak self] in await self?.allowTrackerCalendar() }
        a.openCalendarSettings = { [weak self] in self?.openCalendarSettings() }
        a.close = { [weak self] in self?.closeTrackerPrompt() }
        a.startTodo = { [weak self] id, draft, at in self?.startTodo(id, draft: draft, switchAt: at) ?? false }
        a.doneTodo = { [weak self] id in self?.doneTodo(id) }
        a.markTodoDone = { [weak self] yes in self?.markTodoDone(yes) }
        return a
    }
}
