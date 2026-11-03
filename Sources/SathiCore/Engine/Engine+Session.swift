import Foundation

extension Engine {
    package func session(_ id: HabitID) -> Session? {
        guard case let .session(s) = activities[id] else { return nil }
        return s
    }

    package func startReading() {
        var opened: UUID?
        if let pick = readingPick, ReadingLink.problem(with: pick.url) == nil {
            links.open(pick.url)
            opened = pick.id
        }
        startSession(.reading, readingItem: opened)
    }

    package func startMeditation() { startSession(.meditation) }

    package func startSession(_ id: HabitID, readingItem: UUID? = nil) {
        guard let minutes = sessionMinutes(id) else { sound.beep(); return }
        let workout = sessionWorkout(id)
        let n = clock.now
        let st = state(id)
        let fromReminder = session(id)?.fromReminder ?? (isActive(id) || n >= (st.snoozedUntil ?? st.nextDue))
        close(id)
        let end = n.addingTimeInterval(TimeInterval(minutes) * Timing.minute)
        activities[id] = .session(Session(start: n, end: end, fromReminder: fromReminder, workout: workout, readingItem: readingItem))
        presenter.showSession(id)
        if let sound = startSound(id) { play(sound) }
        requestTick()
    }

    package func finishSession(_ id: HabitID, timedOut: Bool = false) {
        guard let s = session(id) else { return }
        let minutes = Double(Int((s.end.timeIntervalSince(s.start) / Timing.minute).rounded()))
        let amount = doneAmount(id, minutes: minutes)
        let n = clock.now
        record(.done(id, amount, at: n))
        habits[id] = HabitState(nextDue: freshDue(id, lastDone: n))
        close(id)
        if resetsIdea(id) { gymIdea = 0 }
        celebrate(id, amount, readingAsk: timedOut && id == .reading && usesCorner(.reading) ? unreadItem(s)?.id : nil)
    }

    package func stopSession(_ id: HabitID) {
        guard let s = session(id) else { return }
        close(id)
        if s.fromReminder { snoozeHabit(id) }
        if resetsIdea(id) { gymIdea = 0 }
        requestTick()
    }

    func celebrationSound(_ id: HabitID) -> SoundName? {
        switch id {
        case .water, .reading, .gym: return .hero
        case .meditation: return data.prefs.meditation.chime ? .tink : nil
        }
    }

    private func sessionMinutes(_ id: HabitID) -> Int? {
        switch id {
        case .water: return nil
        case .reading: return data.prefs.reading.sessionMinutes
        case .meditation: return data.prefs.meditation.sessionMinutes
        case .gym: return gymWorkout.minutes
        }
    }

    private func sessionWorkout(_ id: HabitID) -> Int? {
        switch id {
        case .water, .reading, .meditation: return nil
        case .gym: return gymWorkoutIndex
        }
    }

    private func doneAmount(_ id: HabitID, minutes: Double) -> Double {
        switch id {
        case .water, .reading, .meditation: return minutes
        case .gym: return 1
        }
    }

    private func startSound(_ id: HabitID) -> SoundName? {
        switch id {
        case .water, .meditation, .gym: return nil
        case .reading: return .purr
        }
    }
}
