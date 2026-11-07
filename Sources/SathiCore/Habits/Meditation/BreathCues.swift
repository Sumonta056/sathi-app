import Foundation

package enum BreathCues {
    package static func dueCue(_ style: BreathingStyle, session s: Session, now: Date, mark: Date?) -> (cue: BreathCue, boundary: Date)? {
        guard !s.isPaused, let current = phase(style, session: s, now: now), current.start < s.end,
              isFresh(current.start, now: now, mark: mark) else { return nil }
        return (BreathCue(current.phase), current.start)
    }

    package static func phaseStart(_ style: BreathingStyle, session s: Session, now: Date) -> Date? {
        phase(style, session: s, now: now)?.start
    }

    package static func nextBoundary(_ style: BreathingStyle, session s: Session, now: Date) -> Date? {
        guard !s.isPaused, let current = phase(style, session: s, now: now) else { return nil }
        let next = current.start.addingTimeInterval(current.length)
        return next < s.end ? next : nil
    }

    package static func dueMinute(session s: Session, now: Date, mark: Date?) -> Date? {
        guard !s.isPaused, let minute = minuteStart(session: s, now: now), minute < s.end else { return nil }
        return isFresh(minute, now: now, mark: mark) ? minute : nil
    }

    package static func minuteStart(session s: Session, now: Date) -> Date? {
        let count = (s.elapsed(at: now) / Timing.minute).rounded(.down)
        guard count >= 1 else { return nil }
        return s.start.addingTimeInterval(count * Timing.minute)
    }

    package static func nextMinute(session s: Session, now: Date) -> Date? {
        guard !s.isPaused else { return nil }
        let count = (s.elapsed(at: now) / Timing.minute).rounded(.down) + 1
        let next = s.start.addingTimeInterval(count * Timing.minute)
        return next < s.end ? next : nil
    }

    private static func isFresh(_ boundary: Date, now: Date, mark: Date?) -> Bool {
        if let mark, boundary <= mark { return false }
        return now.timeIntervalSince(boundary) <= Timing.cueLateLimit
    }

    private static func phase(_ style: BreathingStyle, session s: Session, now: Date) -> (phase: BreathPhase, start: Date, length: TimeInterval)? {
        let elapsed = s.elapsed(at: now)
        guard elapsed >= 0 else { return nil }
        let step = BreathingPattern.step(style, at: elapsed)
        let steps = BreathingPattern.steps(style)
        guard let index = steps.firstIndex(where: { $0.0 == step.phase }) else { return nil }
        let before = steps[..<index].reduce(0) { $0 + $1.1 }
        let offset = Double(step.cycle) * BreathingPattern.cycleLength(style) + before
        return (step.phase, s.start.addingTimeInterval(offset), steps[index].1)
    }
}
