import Foundation
import SathiCore

extension Engine {
    var rangeCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar
    }

    func currentRange(_ kind: ReportRange) -> StatsRange {
        .containing(now, kind: kind, calendar: rangeCalendar)
    }
}
