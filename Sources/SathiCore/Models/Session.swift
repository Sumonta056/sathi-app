import Foundation

package struct Session: Codable, Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var pausedAt: Date?
    package var fromReminder: Bool
    package var workout: Int?
    package var readingItem: UUID?

    package init(
        start: Date,
        end: Date,
        pausedAt: Date? = nil,
        fromReminder: Bool = false,
        workout: Int? = nil,
        readingItem: UUID? = nil
    ) {
        self.start = start
        self.end = end
        self.pausedAt = pausedAt
        self.fromReminder = fromReminder
        self.workout = workout
        self.readingItem = readingItem
    }

    package var isPaused: Bool { pausedAt != nil }

    package func elapsed(at now: Date) -> TimeInterval {
        (pausedAt ?? now).timeIntervalSince(start)
    }

    package func left(at now: Date) -> TimeInterval {
        end.timeIntervalSince(pausedAt ?? now)
    }

    package func paused(at now: Date) -> Session {
        guard !isPaused else { return self }
        var s = self
        s.pausedAt = now.wholeSecond
        return s
    }

    package func resumed(at now: Date) -> Session {
        guard let pausedAt else { return self }
        let gap = max(0, now.wholeSecond.timeIntervalSince(pausedAt))
        var s = self
        s.start = start.addingTimeInterval(gap)
        s.end = end.addingTimeInterval(gap)
        s.pausedAt = nil
        return s
    }
}

extension Session {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        start = try c.decode(Date.self, forKey: .start).wholeSecond
        end = try c.decode(Date.self, forKey: .end).wholeSecond
        pausedAt = try c.decodeIfPresent(Date.self, forKey: .pausedAt)?.wholeSecond
        fromReminder = try c.value(.fromReminder, or: false)
        workout = try c.decodeIfPresent(Int.self, forKey: .workout)
        readingItem = try c.decodeIfPresent(UUID.self, forKey: .readingItem)
    }
}
