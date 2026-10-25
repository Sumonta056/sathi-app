import Foundation

extension Engine {
    package func session(_ id: HabitID) -> Session? {
        guard case let .session(s) = activities[id] else { return nil }
        return s
    }

    package func startReading() { startSession(.reading) }

    package func startMeditation() { startSession(.meditation) }

    package func startSession(_ id: HabitID) {
        guard let minutes = sessionMinutes(id) else { sound.beep(); return }
        let n = clock.now
        let st = state(id)
        let fromReminder = session(id)?.fromReminder ?? (isActive(id) || n >= (st.snoozedUntil ?? st.nextDue))
        close(id)
        let end = n.addingTimeInterval(TimeInterval(minutes) * Timing.minute)
        activities[id] = .session(Session(start: n, end: end, fromReminder: fromReminder))
        presenter.showSession(id)
        if let sound = startSound(id) { play(sound) }
        requestTick()
    }

    package func finishSession(_ id: HabitID) {
        guard let s = session(id) else { return }
        let minutes = Double(Int((s.end.timeIntervalSince(s.start) / Timing.minute).rounded()))
        let n = clock.now
        record(.done(id, minutes, at: n))
        habits[id] = HabitState(nextDue: freshDue(id, lastDone: n))
        close(id)
        celebrate(id, minutes)
    }

    package func stopSession(_ id: HabitID) {
        guard let s = session(id) else { return }
        close(id)
        if s.fromReminder { snoozeHabit(id) }
        requestTick()
    }

    func celebrationSound(_ id: HabitID) -> SoundName? {
        switch id {
        case .water, .reading: return .hero
        case .meditation: return data.prefs.meditation.chime ? .tink : nil
        }
    }

    private func sessionMinutes(_ id: HabitID) -> Int? {
        switch id {
        case .water: return nil
        case .reading: return data.prefs.reading.sessionMinutes
        case .meditation: return data.prefs.meditation.sessionMinutes
        }
    }

    private func startSound(_ id: HabitID) -> SoundName? {
        switch id {
        case .water, .meditation: return nil
        case .reading: return .purr
        }
    }
}
