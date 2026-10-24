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
        if pausedUntil == nil { enqueueDueHabits() }

        switch phase {
        case .bubble:
            if now >= ignoreDeadline { snooze() }
        case .session:
            if now >= sessionEnd { finishSession() }
        default:
            break
        }

        if phase == .idle, pausedUntil == nil, !queue.isEmpty {
            present(queue.removeFirst())
        }
        updateStatus()
        scheduleNextTick()
    }

    package func nextTickDelay() -> TimeInterval {
        let showsCountdown = phase == .idle && pausedUntil == nil
        return TickPlanner.delay(
            now: now,
            phase: phase,
            deadlines: upcomingDeadlines(),
            focusRemaining: showsCountdown ? focus.map(remaining) : nil
        )
    }

    func requestTick() {
        guard isRunning else { return }
        schedule(after: 0)
    }

    private func enqueueDueHabits() {
        for id in HabitID.allCases where enabled(id) && !isDue(id) {
            let st = state(id)
            let due = now >= (st.snoozedUntil ?? st.nextDue)
            if due && (forced.contains(id) || rules(id).isActiveTime(now)) {
                queue.append(id)
            }
        }
    }

    private func upcomingDeadlines() -> [Date] {
        var deadlines: [Date] = []
        if let p = pausedUntil { deadlines.append(p) }
        if case .bubble = phase { deadlines.append(ignoreDeadline) }
        if phase == .session { deadlines.append(sessionEnd) }
        if pausedUntil == nil {
            for id in HabitID.allCases where enabled(id) && !isDue(id) {
                deadlines.append(now.addingTimeInterval(remaining(id)))
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
        case .lock: showLock(id)
        }
    }

    private func showBubble(_ id: HabitID, _ level: Level) {
        copy = Copywriter.pick(id, level, name: data.prefs.name)
        ignoreDeadline = clock.now.addingTimeInterval(TimeInterval(data.prefs.ignoreMinutes) * Timing.minute)
        phase = .bubble(id, level)
        presenter.showBubble(id, level)
        play(level == .persist ? .ping : Self.greeting(id))
    }

    private static func greeting(_ id: HabitID) -> SoundName {
        switch id {
        case .water: return .glass
        case .reading: return .purr
        }
    }

    private func showLock(_ id: HabitID) {
        phase = .lock(id)
        presenter.showLock(id)
        play(.sosumi)
    }
}
