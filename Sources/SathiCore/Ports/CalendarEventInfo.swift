import Foundation

package struct CalendarEventInfo: Equatable, Hashable, Identifiable, Sendable {
    package var id: String
    package var title: String
    package var start: Date
    package var end: Date
    package var calendarID: String
    package var isAllDay: Bool
    package var declined: Bool

    package init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        calendarID: String,
        isAllDay: Bool = false,
        declined: Bool = false
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.calendarID = calendarID
        self.isAllDay = isAllDay
        self.declined = declined
    }
}
