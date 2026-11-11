import Foundation

extension Engine {
    package var runningActivity: RunningActivity? { data.live.tracker.running }
    package var trackerPrompt: PromptState? { data.live.tracker.prompt }
    package var trackerQuietUntil: Date? { data.live.tracker.running?.quietUntil }

    package func startActivity(_ draft: ActivityDraft, switchAt: Date? = nil) {
        guard trackerPrefs.isOn, let text = ActivityText.clean(draft.text) else { return sound.beep() }
        let n = clock.now.wholeSecond
        if data.live.tracker.awaySince != nil { returnFromAway(at: n, welcomes: false) }
        var at = min(switchAt?.wholeSecond ?? n, n)
        if let r = data.live.tracker.running {
            at = max(at, r.start)
            endRunningActivity(at: at)
        }
        clearTrackerPrompt()
        clearAwayRuntime()
        trackerRuntime.whatNowAt = nil
        var d = draft
        d.text = text
        beginActivity(d, at: at)
        requestTick()
    }

    package func skipTrackerPrompt(switchAt: Date? = nil) {
        guard let p = data.live.tracker.prompt else { return }
        let n = clock.now.wholeSecond
        switch p.kind {
        case .stillOnIt:
            data.live.tracker.running?.askAt = n.addingTimeInterval(trackerAskEvery)
        case .whatNow:
            if p.switchFrom != nil, let r = data.live.tracker.running {
                endRunningActivity(at: max(r.start, min(switchAt?.wholeSecond ?? n, n)))
            }
            trackerRuntime.whatNowAt = n.addingTimeInterval(trackerAskEvery)
        case .center, .welcomeBack, .eventAsk:
            break
        }
        clearTrackerPrompt()
        requestTick()
    }

    package func stillOnIt(minutes: Int? = nil) {
        guard data.live.tracker.running != nil else { return }
        let n = clock.now.wholeSecond
        if let p = data.live.tracker.prompt, p.kind == .stillOnIt,
           AskTime.waitedMinutes(shownAt: p.shownAt, now: n) != nil { return stillOnItLate() }
        let m = minutes ?? trackerPrefs.askEveryMinutes
        let next = n.addingTimeInterval(TimeInterval(m) * Timing.minute)
        data.live.tracker.running?.askAt = next
        data.live.tracker.running?.lastAnswer = n
        data.live.tracker.running?.confirmedUntil = next
        clearTrackerPrompt()
        requestTick()
    }

    package func stillOnItLate() {
        guard data.live.tracker.running != nil else { return }
        let n = clock.now.wholeSecond
        data.live.tracker.running?.askAt = n.addingTimeInterval(trackerAskEvery)
        data.live.tracker.running?.lastAnswer = n
        data.live.tracker.running?.confirmedUntil = n
        clearTrackerPrompt()
        requestTick()
    }

    package func doneActivity() {
        guard let r = data.live.tracker.running else { return }
        let n = clock.now.wholeSecond
        data.live.tracker.running?.quietUntil = nil
        setTrackerPrompt(PromptState(kind: .whatNow, shownAt: n, askTime: n, switchFrom: r.lastAnswer, doneAt: n), byUser: true)
        requestTick()
    }

    package func continueActivity(switchAt: Date? = nil) {
        guard let resume = data.live.tracker.prompt?.resume else { return }
        startActivity(resume, switchAt: switchAt)
    }

    package func backToLastActivity() {
        guard let last = data.live.tracker.lastActivity else { return }
        startActivity(last)
    }

    package func iWasHere() {
        guard data.live.tracker.prompt?.kind == .welcomeBack, trackerRuntime.lastAway?.fromIdle == true else { return }
        restoreAwayItem()
        clearTrackerPrompt()
        clearAwayRuntime()
        requestTick()
    }

    package func closeTrackerPrompt() {
        guard data.live.tracker.prompt != nil else { return }
        if let done = pendingDoneAt { endRunningActivity(at: done) }
        clearTrackerPrompt()
        if data.live.tracker.running == nil {
            trackerRuntime.whatNowAt = clock.now.wholeSecond.addingTimeInterval(trackerAskEvery)
        }
        requestTick()
    }

    package func openTrackerPanel() {
        endQuietTime()
        guard trackerPrefs.isOn, data.live.tracker.prompt?.kind != .center else { return }
        let n = clock.now.wholeSecond
        if let done = pendingDoneAt { endRunningActivity(at: done) }
        if data.live.tracker.awaySince != nil { returnFromAway(at: n, welcomes: false) }
        setTrackerPrompt(PromptState(kind: .center, shownAt: n, askTime: n), byUser: true)
    }

    package func trackerShortcutPressed() {
        openTrackerPanel()
    }

    package func endQuietTime() {
        guard data.live.tracker.running?.quietUntil != nil else { return }
        data.live.tracker.running?.quietUntil = nil
        requestTick()
    }

    package func presenceChanged(_ event: PresenceEvent) {
        guard trackerPrefs.isOn else { return }
        handlePresence(event)
    }

    package func closeTrackerEndOfDay() {
        guard trackerRuntime.endOfDayShowing else { return }
        trackerRuntime.endOfDayShowing = false
        presenter.closeTrackerEndOfDay()
    }

    package func openActivityReport(_ day: DayKey) {
        closeTrackerEndOfDay()
        openMain(.activities(day))
    }

    func clearAwayRuntime() {
        trackerRuntime.lastAway = nil
        trackerRuntime.awayItems = []
        trackerRuntime.endedByAway = nil
        trackerRuntime.loggedWhileAway = []
    }
}
