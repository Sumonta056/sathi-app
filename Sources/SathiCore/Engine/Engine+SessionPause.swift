import Foundation

extension Engine {
    package func pauseSession(_ id: HabitID) {
        guard pausable(id), let s = session(id), !s.isPaused else { return }
        activities[id] = .session(s.paused(at: clock.now))
        sessionPaused(id)
        requestTick()
    }

    package func resumeSession(_ id: HabitID) {
        guard pausable(id), let s = session(id), s.isPaused else { return }
        activities[id] = .session(s.resumed(at: clock.now))
        sessionResumed(id)
        requestTick()
    }

    private func pausable(_ id: HabitID) -> Bool {
        switch id {
        case .water, .reading, .gym: return false
        case .meditation: return true
        }
    }

    func syncMeditationSession() {
        let s = session(.meditation)
        if data.live.meditationSession != s { data.live.meditationSession = s }
    }

    func endPausedSessionIfNewDay() {
        guard let pausedAt = session(.meditation)?.pausedAt, now >= calendar.nextDay(after: pausedAt) else { return }
        close(.meditation)
        requestTick()
    }
}
