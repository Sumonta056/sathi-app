import Foundation

package struct CalendarRangeTitle: Equatable, Sendable {
    package let main: String
    package let year: String

    package var full: String { main + " " + year }
}

extension Copywriter {
    package static let calendarPageTitle = "Calendar"
    package static let calendarExperimentalTag = "Experimental"
    package static let calendarSettingLabel = "Calendar page (experimental)"
    package static let calendarSettingHint = "Shows your events and activities on one time grid."
    package static let calendarToday = "Today"
    package static let calendarDayBoundary = "6 AM to 6 AM"
    package static let calendarGateNotice = "Sathi needs calendar access to show your events."

    package static func calendarRangeTitle(_ range: CalendarPageRange, calendar: Calendar) -> CalendarRangeTitle {
        let zone = calendar.timeZone
        let g = Calendar.gregorian(in: zone)
        guard let first = range.days.first?.start(in: g), let last = range.days.last?.start(in: g) else {
            return CalendarRangeTitle(main: "", year: "")
        }
        let year = rangeDate(last, "yyyy", zone)
        switch range.kind {
        case .day: return CalendarRangeTitle(main: rangeDate(first, "EEE d MMM", zone), year: year)
        case .week: return CalendarRangeTitle(main: rangeDate(first, "d MMM", zone) + " to " + rangeDate(last, "d MMM", zone), year: year)
        case .month: return CalendarRangeTitle(main: rangeDate(first, "MMMM", zone), year: year)
        }
    }
}
