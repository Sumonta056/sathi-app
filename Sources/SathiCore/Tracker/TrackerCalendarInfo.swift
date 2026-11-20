import Foundation

package struct TrackerCalendarInfo: Equatable {
    package var access: CalendarAccess
    package var calendars: [CalendarChoice]
    package var defaultID: String?

    package init(access: CalendarAccess, calendars: [CalendarChoice], defaultID: String?) {
        self.access = access
        self.calendars = calendars
        self.defaultID = defaultID
    }
}
