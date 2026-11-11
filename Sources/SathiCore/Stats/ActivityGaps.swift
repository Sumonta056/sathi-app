import Foundation

package enum ActivityGaps {
    package static func spans(_ day: ActivityDay, now: Date, isTrackerDay: Bool) -> [DateInterval] {
        guard isTrackerDay else { return [] }
        return ActivityTimeline.segments(day).compactMap { s in
            guard s.kind == .notLogged else { return nil }
            let end = min(s.interval.end, now)
            guard end.timeIntervalSince(s.interval.start) >= Timing.activityMinimum else { return nil }
            return DateInterval(start: s.interval.start, end: end)
        }
    }
}
