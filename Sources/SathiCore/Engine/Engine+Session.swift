import Foundation

extension Engine {
    package var sessionHabit: HabitID? {
        guard case let .session(id) = phase else { return nil }
        return id
    }

    package func startReading() { startSession(.reading) }

    package func startMeditation() { startSession(.meditation) }

    package func startSession(_ id: HabitID) {
        guard let minutes = sessionMinutes(id), phase == .idle || isActive(id) else { sound.beep(); return }
        let n = clock.now
        let st = state(id)
        if sessionHabit != id { sessionFromReminder = isDue(id) || n >= (st.snoozedUntil ?? st.nextDue) }
        presenter.closeBubble()
        presenter.closeLock()
        queue.removeAll { $0 == id }
        sessionStart = n
        sessionEnd = n.addingTimeInterval(TimeInterval(minutes) * Timing.minute)
        phase = .session(id)
        presenter.showSession()
        if let sound = startSound(id) { play(sound) }
        requestTick()
    }

    package func finishSession() {
        guard let id = sessionHabit else { return }
        let minutes = Double(Int((sessionEnd.timeIntervalSince(sessionStart) / Timing.minute).rounded()))
        let n = clock.now
        record(.done(id, minutes, at: n))
        habits[id] = HabitState(nextDue: freshDue(id, lastDone: n))
        presenter.closeSession()
        phase = .idle
        celebrate(id, minutes)
    }

    package func stopSession() {
        guard let id = sessionHabit else { return }
        presenter.closeSession()
        if sessionFromReminder { snoozeHabit(id) }
        phase = .idle
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
