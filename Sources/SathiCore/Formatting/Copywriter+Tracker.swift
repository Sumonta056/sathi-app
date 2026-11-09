import Foundation

extension Copywriter {
    package static let trackerNoCategory = "No category"
    package static let trackerOpen = "Open"
    package static let trackerNow = "Now"
    package static let trackerAway = "Away"
    package static let trackerNotLogged = "Not logged"

    package static func trackerDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds / Timing.minute))
        let h = total / Limits.minutesPerHour
        let m = total % Limits.minutesPerHour
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    package static func trackerTileDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds / Timing.minute))
        guard total >= Limits.minutesPerHour else { return "\(total) min" }
        return String(format: "%d h %02d", total / Limits.minutesPerHour, total % Limits.minutesPerHour)
    }

    package static func trackerLengthLabel(_ length: ActivityLength) -> String {
        length.minutes.map { trackerDuration(TimeInterval($0) * Timing.minute) } ?? trackerOpen
    }

    package static func trackerMinutesChip(_ minutes: Int) -> String { "\(minutes) min" }

    package static func trackerAskOffsetLabel(_ minutes: Int) -> String {
        minutes == 0 ? "When it ends" : "\(minutes) min after"
    }

    package static func trackerSummary(category: String?, askOffsetMinutes: Int) -> String {
        (category ?? trackerNoCategory) + " · ask " + trackerAskOffsetLabel(askOffsetMinutes).lowercased()
    }

    package static func trackerClock(_ date: Date, calendar: Calendar) -> String {
        quickClock(date, calendar: calendar)
    }

    package static func trackerSpan(_ start: Date, _ end: Date, calendar: Calendar) -> String {
        trackerClock(start, calendar: calendar) + " – " + trackerClock(end, calendar: calendar)
    }

    package static func trackerAwayPlace(_ place: AwayPlace) -> String {
        switch place {
        case .lunch: return "Lunch"
        case .meeting: return "Meeting"
        case .walk: return "Walk"
        case .commute: return "Commute"
        case .other: return "Other"
        case .breakTime: return "Break"
        }
    }

    package static func trackerAwayText(_ place: AwayPlace?) -> String {
        place.map { trackerAway + " · " + trackerAwayPlace($0) } ?? trackerAway
    }

    package static func trackerBuddyText(_ id: HabitID, detail: String?) -> String {
        let name = ActivityCategory.buddy(id).name
        let base = id == .meditation ? "Breathing" : name
        return detail.map { base + " · " + $0 } ?? base
    }
}
