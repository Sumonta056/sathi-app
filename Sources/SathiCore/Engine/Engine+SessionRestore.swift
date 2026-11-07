import Foundation

extension Engine {
    func restoreMeditationSession() {
        guard let saved = data.live.meditationSession else { return }
        let n = clock.now
        guard canRestore(saved, at: n) else {
            data.live.meditationSession = nil
            return
        }
        close(.meditation)
        activities[.meditation] = .session(saved)
        presenter.showSession(.meditation)
        sessionRestored()
    }

    private func canRestore(_ s: Session, at n: Date) -> Bool {
        if let pausedAt = s.pausedAt { return calendar.isDate(pausedAt, inSameDayAs: n) }
        return s.end > n && calendar.isDate(s.start, inSameDayAs: n)
    }
}
