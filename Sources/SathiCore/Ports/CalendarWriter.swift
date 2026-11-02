import Foundation

package enum CalendarAccess: Equatable, Sendable {
    case notAsked
    case allowed
    case denied
}

package struct CalendarChoice: Equatable, Identifiable, Sendable {
    package var id: String
    package var title: String
    package var account: String
    package var colorHex: UInt32

    package init(id: String, title: String, account: String, colorHex: UInt32) {
        self.id = id
        self.title = title
        self.account = account
        self.colorHex = colorHex
    }
}

package struct CalendarEventDraft: Equatable, Sendable {
    package var calendarID: String
    package var title: String
    package var start: Date
    package var end: Date

    package init(calendarID: String, title: String, start: Date, end: Date) {
        self.calendarID = calendarID
        self.title = title
        self.start = start
        self.end = end
    }
}

package enum CalendarSaveResult: Equatable, Sendable {
    case saved(eventID: String)
    case calendarMissing
    case failed
}

@MainActor
package protocol CalendarWriter: AnyObject {
    var access: CalendarAccess { get }
    func requestAccess() async -> CalendarAccess
    func calendars() -> [CalendarChoice]
    func defaultCalendarID() -> String?
    func save(_ draft: CalendarEventDraft) -> CalendarSaveResult
    func update(eventID: String, draft: CalendarEventDraft) -> CalendarSaveResult
}
