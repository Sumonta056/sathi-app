import Foundation

extension Engine {
    var trackerSessionRuns: Bool { HabitID.allCases.contains { session($0) != nil } }

    var trackerIsQuiet: Bool {
        guard let until = data.live.tracker.running?.quietUntil else { return false }
        return clock.now < until
    }

    var trackerIsBusy: Bool {
        pausedUntil != nil || timeBlock?.isRunning == true || trackerSessionRuns || trackerIsQuiet
    }

    func runTrackerTick() {
        let n = clock.now
        endActivityAtMidnight(n)
        checkIdle(n)
        tickTrackerEvents()
        planTrackerPrompt(n)
        presentTrackerPrompt()
        showTrackerEndOfDayIfDue(n)
    }

    func trackerDeadlineList() -> [Date] {
        let n = clock.now
        let t = data.live.tracker
        var list: [Date] = trackerEventDeadlines
        if let r = t.running {
            list += [r.askAt, calendar.nextDay(after: r.start)]
            if let q = r.quietUntil { list.append(q) }
        }
        if let w = trackerRuntime.whatNowAt { list.append(w) }
        if let s = trackerHours.nextStart(after: n) { list.append(s) }
        list.append(trackerHours.hours(on: n).end)
        if t.awaySince == nil {
            list.append((t.lastInput ?? n).addingTimeInterval(idleLimit))
        }
        return list.filter { $0 > n }
    }

    func setTrackerPrompt(_ prompt: PromptState) {
        closeShownTrackerPrompt()
        data.live.tracker.prompt = prompt
        presentTrackerPrompt()
    }

    func clearTrackerPrompt() {
        closeShownTrackerPrompt()
        data.live.tracker.prompt = nil
    }

    func presentTrackerPrompt() {
        guard let p = data.live.tracker.prompt, trackerRuntime.shownPrompt != p.kind, canShowTrackerPrompt(p) else { return }
        closeShownTrackerPrompt()
        presenter.showTrackerPrompt(p.kind)
        trackerRuntime.shownPrompt = p.kind
        if p.kind == .whatNow || p.kind == .stillOnIt, trackerPrefs.playsSound { play(.trackerPrompt) }
    }

    var idleLimit: TimeInterval { TimeInterval(trackerPrefs.idleMinutes) * Timing.minute }

    private func closeShownTrackerPrompt() {
        guard let k = trackerRuntime.shownPrompt else { return }
        presenter.closeTrackerPrompt(k)
        trackerRuntime.shownPrompt = nil
    }

    private func canShowTrackerPrompt(_ p: PromptState) -> Bool {
        guard trackerPrefs.isOn, !isAnyLockShowing else { return false }
        switch p.kind {
        case .center: return true
        case .welcomeBack: return pausedUntil == nil && timeBlock?.isRunning != true && !trackerSessionRuns
        case .whatNow, .stillOnIt, .eventAsk: return !trackerIsBusy && data.live.tracker.awaySince == nil
        }
    }

    private func planTrackerPrompt(_ n: Date) {
        let t = data.live.tracker
        guard t.prompt == nil, t.awaySince == nil, !trackerIsBusy, !isAnyLockShowing else { return }
        if let r = t.running {
            guard n >= r.askAt, trackerHours.isTrackerDay(n) else { return }
            setTrackerPrompt(PromptState(kind: .stillOnIt, shownAt: n, askTime: r.askAt))
            return
        }
        guard trackerHours.isInside(n) else { return }
        let due = max(trackerRuntime.whatNowAt ?? .distantPast, trackerHours.hours(on: n).start)
        guard n >= due else { return }
        trackerRuntime.whatNowAt = nil
        setTrackerPrompt(PromptState(kind: .whatNow, shownAt: n, askTime: n))
    }

    private func endActivityAtMidnight(_ n: Date) {
        guard let r = data.live.tracker.running else { return }
        let midnight = calendar.nextDay(after: r.start)
        guard n >= midnight else { return }
        endRunningOnInterrupt(at: min(r.confirmedUntil, midnight))
        if data.live.tracker.prompt?.kind == .stillOnIt || data.live.tracker.prompt?.switchFrom != nil { clearTrackerPrompt() }
    }

    private func showTrackerEndOfDayIfDue(_ n: Date) {
        let p = trackerPrefs
        guard p.endOfDayOn, !trackerRuntime.endOfDayShowing, data.live.tracker.running == nil,
              !isAnyLockShowing, trackerHours.isTrackerDay(n) else { return }
        let today = DayKey(n, calendar: calendar)
        guard data.live.tracker.lastEndOfDay != today, n >= trackerHours.hours(on: n).end else { return }
        data.live.tracker.lastEndOfDay = today
        trackerRuntime.endOfDayShowing = true
        presenter.showTrackerEndOfDay()
    }
}
