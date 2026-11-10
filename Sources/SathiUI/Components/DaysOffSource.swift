import SathiCore
import SwiftUI

@MainActor
struct DaysOffSource {
    var accent: Color
    var hint: String
    var upcoming: () -> [DayKey]
    var month: (Int) -> DayOffMonth
    var add: (DayKey) -> Void
    var remove: (DayKey) -> Void

    static func habit(_ id: HabitID, _ e: Engine) -> DaysOffSource {
        DaysOffSource(
            accent: Night.accent(id),
            hint: DaysOffCard.hint(id),
            upcoming: { e.upcomingDaysOff(id) },
            month: { e.dayOffMonth(id, offset: $0) },
            add: { e.addDayOff(id, key: $0) },
            remove: { e.removeDayOff(id, $0) }
        )
    }

    static func tracker(_ e: Engine) -> DaysOffSource {
        DaysOffSource(
            accent: Night.tracker,
            hint: Copywriter.trackerDaysOffHint,
            upcoming: { e.upcomingTrackerDaysOff() },
            month: { e.trackerDayOffMonth(offset: $0) },
            add: { e.addTrackerDayOff($0) },
            remove: { e.removeTrackerDayOff($0) }
        )
    }
}
