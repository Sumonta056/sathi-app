import Foundation

extension Engine {
    var trackerDeadlines: [Date] { trackerPrefs.isOn ? trackerDeadlineList() : [] }
    var trackerHoldsBuddyPopups: Bool { trackerPrefs.isOn && trackerIsQuiet }

    func tickTracker() {
        guard trackerPrefs.isOn else { return todoDueCheckedUntil = nil }
        runTrackerTick()
    }

    func restoreTracker() {
        guard trackerPrefs.isOn else { return }
        startTrackerPlatform()
        let n = clock.now
        if let r = data.live.tracker.running, n >= calendar.nextDay(after: r.start) {
            endRunningActivity(at: min(r.confirmedUntil, calendar.nextDay(after: r.start)))
        }
        if data.live.tracker.awaySince != nil { returnFromAway(at: n) }
        if let p = data.live.tracker.prompt, isStale(p, now: n) { data.live.tracker.prompt = nil }
        if data.live.tracker.prompt?.kind != .welcomeBack { clearAwayRuntime() }
    }

    func stopTracker() {
        stopTrackerPlatform()
    }

    func trackerPrefsChanged(from old: TrackerPrefs) {
        let new = data.prefs.tracker
        if old.isOn && !new.isOn {
            if let r = data.live.tracker.running { endRunningOnInterrupt(at: min(r.confirmedUntil, clock.now), interrupt: clock.now) }
            clearTrackerPrompt()
            closeEventNote()
            closeTrackerEndOfDay()
            data.live.tracker.awaySince = nil
            data.live.tracker.awayCause = nil
            data.live.tracker.awayPlan = nil
            stopTrackerPlatform()
        } else if new.isOn && isRunning {
            startTrackerPlatform()
        }
        syncCalendarChangeListener()
        requestTick()
    }

    func trackerBreakChanged(from old: Date?) {
        guard trackerPrefs.isOn else { return }
        if old == nil, pausedUntil != nil {
            beginAway(at: clock.now, cause: .onBreak)
        } else if old != nil, pausedUntil == nil, data.live.tracker.awayCause == .onBreak {
            endBreakAway(at: clock.now)
        }
    }

    func trackerBlockStarted() {
        guard trackerPrefs.isOn else { return }
        endRunningOnInterrupt(at: clock.now)
        clearTrackerPrompt()
        requestTick()
    }

    func trackerBlockSaved(_ block: TimeBlock, end: Date) {
        guard trackerPrefs.isOn else { return }
        var from = block.startedAt
        while from < end {
            let to = min(end, calendar.nextDay(after: from))
            storeActivity(Activity(kind: .timeBlock, text: block.title, start: from, end: to))
            from = to
        }
        requestTick()
    }

    private func isStale(_ p: PromptState, now n: Date) -> Bool {
        let running = data.live.tracker.running != nil
        switch p.kind {
        case .stillOnIt: return !running
        case .whatNow: return p.switchFrom == nil ? !trackerHours.isInside(n) : !running && p.resume == nil
        case .todoDue: return !trackerHours.isInside(n)
        case .center, .welcomeBack, .eventAsk: return false
        }
    }

    func draft(of r: RunningActivity) -> ActivityDraft {
        ActivityDraft(
            text: r.text,
            category: r.category,
            length: r.expectedLength,
            calendarID: r.calendarID,
            sourceEventID: r.sourceEventID
        )
    }

    private func startTrackerPlatform() {
        if !trackerRuntime.presenceStarted {
            presence.start { [weak self] event in self?.presenceChanged(event) }
            trackerRuntime.presenceStarted = true
        }
        let shortcut = trackerPrefs.shortcut
        guard trackerRuntime.registeredShortcut != shortcut else { return }
        if trackerRuntime.registeredShortcut != nil { hotkeys.unregister() }
        let ok = hotkeys.register(shortcut) { [weak self] in self?.trackerShortcutPressed() }
        trackerRuntime.registeredShortcut = ok ? shortcut : nil
    }

    private func stopTrackerPlatform() {
        if trackerRuntime.presenceStarted { presence.stop() }
        if trackerRuntime.registeredShortcut != nil { hotkeys.unregister() }
        trackerRuntime.presenceStarted = false
        trackerRuntime.registeredShortcut = nil
    }
}
