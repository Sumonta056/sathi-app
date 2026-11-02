import Foundation
import SathiCore

@MainActor
package final class SpyCalendarWriter: CalendarWriter {
    package var access: CalendarAccess = .allowed
    package var choices: [CalendarChoice] = [
        CalendarChoice(id: "work", title: "Gmail Work", account: "Gmail", colorHex: 0x4285F4),
        CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0x34A853)
    ]
    package var defaultID: String?
    package var nextSaveResult: CalendarSaveResult?
    package var nextUpdateResult: CalendarSaveResult?
    package private(set) var saved: [CalendarEventDraft] = []
    package private(set) var updated: [(String, CalendarEventDraft)] = []
    package private(set) var requestCount = 0

    package init() {}

    package func requestAccess() async -> CalendarAccess {
        requestCount += 1
        return access
    }

    package func calendars() -> [CalendarChoice] { choices }

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
