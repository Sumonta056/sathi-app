import Foundation

extension TrackerPrefs {
    package mutating func setStart(_ minutes: Int) {
        startMinutes = min(max(minutes, 0), Limits.minutesPerDay - Limits.scheduleSlotMinutes)
        if endMinutes <= startMinutes { endMinutes = startMinutes + Limits.scheduleSlotMinutes }
    }

    package mutating func setEnd(_ minutes: Int) {
        endMinutes = min(max(minutes, Limits.scheduleSlotMinutes), Limits.minutesPerDay)
        if startMinutes >= endMinutes { startMinutes = endMinutes - Limits.scheduleSlotMinutes }
    }

    static func ordered(start: Int, end: Int) -> (Int, Int) {
        guard start >= end else { return (start, end) }
        let s = min(start, Limits.minutesPerDay - Limits.scheduleSlotMinutes)
        return (s, s + Limits.scheduleSlotMinutes)
    }
}
