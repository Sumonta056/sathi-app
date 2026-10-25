import Foundation

extension Engine {
    package func start() {
        guard !isRunning else { return }
        isRunning = true
        tick()
    }

    package func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    package func tick() {
        now = clock.now
        if let p = pausedUntil, now >= p { pausedUntil = nil }
        for id in HabitID.allCases {
            endIfExpired(id)
        }
        if pausedUntil == nil { presentDueHabits() }
        updateStatus()
        scheduleNextTick()
    }

    package func nextTickDelay() -> TimeInterval {
        let showsCountdown = activities.isEmpty && pausedUntil == nil
        return TickPlanner.delay(
            now: now,
            inSession: HabitID.allCases.contains { session($0) != nil },
            deadlines: upcomingDeadlines(),
            focusRemaining: showsCountdown ? focus.map(remaining) : nil
        )
    }

    func requestTick() {
        guard isRunning else { return }
        schedule(after: 0)
    }

    private func endIfExpired(_ id: HabitID) {
        switch activities[id] {
        case let .bubble(_, _, deadline) where now >= deadline: snooze(id)
        case let .session(s) where now >= s.end: finishSession(id)
        default: break
        }
    }

    private func presentDueHabits() {
        for id in HabitID.allCases where enabled(id) && !isActive(id) {
            let st = state(id)
            let due = now >= (st.snoozedUntil ?? st.nextDue)
            if due && (forced.contains(id) || rules(id).isActiveTime(now)) {
                present(id)
            }
        }
    }

    private func upcomingDeadlines() -> [Date] {
        var deadlines: [Date] = []
        if let p = pausedUntil { deadlines.append(p) }
        for id in HabitID.allCases {
            switch activities[id] {
            case let .bubble(_, _, deadline): deadlines.append(deadline)
            case let .session(s): deadlines.append(s.end)
            case .lock: break
            case nil:
                if pausedUntil == nil && enabled(id) { deadlines.append(now.addingTimeInterval(remaining(id))) }
            }
        }
        return deadlines
    }

    private func scheduleNextTick() {
        guard isRunning else { return }
        schedule(after: nextTickDelay())
    }

    private func schedule(after delay: TimeInterval) {
        timer?.invalidate()
        let t = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = TickPlanner.tolerance(for: delay)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func present(_ id: HabitID) {
        forced.remove(id)
        switch EscalationPolicy.presentation(for: strictness(id), snoozes: state(id).snoozes) {
        case let .bubble(level): showBubble(id, level)
        case .lock where HabitID.allCases.contains(where: { phase($0) == .lock }): showBubble(id, .persist)
        case .lock: showLock(id)
        }
    }

    private func showBubble(_ id: HabitID, _ level: Level) {
        let copy = Copywriter.pick(id, level, name: data.prefs.general.name)
        let deadline = clock.now.addingTimeInterval(TimeInterval(data.prefs.general.ignoreMinutes) * Timing.minute)
        activities[id] = .bubble(level, copy: copy, ignoreDeadline: deadline)
        presenter.showBubble(id, level)
        play(level == .persist ? .ping : Self.greeting(id))
    }

    private static func greeting(_ id: HabitID) -> SoundName {
        switch id {
        case .water: return .glass
        case .reading: return .purr
        case .meditation: return .tink
        }
    }

    private func showLock(_ id: HabitID) {
        activities[id] = .lock
        presenter.showLock(id)
        play(.sosumi)
    }
}
