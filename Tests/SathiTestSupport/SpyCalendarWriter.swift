import Foundation
import SathiCore

@MainActor
package final class SpyCalendarWriter: CalendarWriter {
    package var accessValue: CalendarAccess = .allowed
    package private(set) var accessReads = 0
    package var access: CalendarAccess {
        get {
            accessReads += 1
            return accessValue
        }
        set { accessValue = newValue }
    }
    package var choices: [CalendarChoice] = [
        CalendarChoice(id: "work", title: "Gmail Work", account: "Gmail", colorHex: 0x4285F4),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)
    ]
    package var defaultID: String?
    package var accessAfterRequest: CalendarAccess?
    package private(set) var calendarsCalls = 0
    package var nextSaveResult: CalendarSaveResult?
    package var nextUpdateResult: CalendarSaveResult?
    package private(set) var saved: [CalendarEventDraft] = []
    package private(set) var updated: [(String, CalendarEventDraft)] = []
    package private(set) var requestCount = 0

    package init() {}

    package func requestAccess() async -> CalendarAccess {
        requestCount += 1
        if let after = accessAfterRequest { accessValue = after }
        return access
    }

    package func calendars() -> [CalendarChoice] {
        calendarsCalls += 1
        return choices
    }

    package func defaultCalendarID() -> String? { defaultID }

    package func save(_ draft: CalendarEventDraft) -> CalendarSaveResult {
        saved.append(draft)
        return nextSaveResult ?? .saved(eventID: "e\(saved.count)")
    }

    package func update(eventID: String, draft: CalendarEventDraft) -> CalendarSaveResult {
        updated.append((eventID, draft))
        return nextUpdateResult ?? .saved(eventID: eventID)
    }
}
