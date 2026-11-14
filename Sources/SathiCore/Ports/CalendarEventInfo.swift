import Foundation

package struct CalendarEventInfo: Equatable, Hashable, Identifiable, Sendable {
    package var id: String
    package var title: String
    package var start: Date
    package var end: Date
    package var calendarID: String
    package var isAllDay: Bool
    package var declined: Bool
    package var isRepeating: Bool
    package var hasGuests: Bool

    package init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        calendarID: String,
        isAllDay: Bool = false,
        declined: Bool = false,
        isRepeating: Bool = false,
        hasGuests: Bool = false
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.calendarID = calendarID
        self.isAllDay = isAllDay
        self.declined = declined
        self.isRepeating = isRepeating
        self.hasGuests = hasGuests
    }

    package var isReadOnlyInSathi: Bool { isRepeating || hasGuests }
}
