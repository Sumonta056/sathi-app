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
    package var updateResultQueue: [CalendarSaveResult] = []
    package private(set) var saved: [CalendarEventDraft] = []
    package private(set) var updated: [(String, CalendarEventDraft)] = []
    package private(set) var requestCount = 0
    package var readable: [CalendarChoice]?
    package private(set) var readableCalls = 0
    package var eventsValue: [CalendarEventInfo] = []
    package var nextDeleteResult = true
    package var deleteResults: [String: Bool] = [:]
    package private(set) var deleted: [String] = []
    package private(set) var eventReads: [DateInterval] = []
    package var mirrorsWrites = false
    package var lockedEventIDs: Set<String> = []

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
        let result = nextSaveResult ?? .saved(eventID: "e\(saved.count)")
        if mirrorsWrites, case let .saved(id) = result { eventsValue.append(info(id, draft)) }
        return result
    }

    package func update(eventID: String, draft: CalendarEventDraft) -> CalendarSaveResult {
        updated.append((eventID, draft))
        if lockedEventIDs.contains(eventID) { return .lockedEvent }
        let result = updateResultQueue.isEmpty
            ? (nextUpdateResult ?? .saved(eventID: eventID))
            : updateResultQueue.removeFirst()
        if mirrorsWrites, case .saved = result, let i = eventsValue.firstIndex(where: { $0.id == eventID }) {
            eventsValue[i] = info(eventID, draft)
        }
        return result
    }

    @discardableResult
    package func delete(eventID: String) -> Bool {
        deleted.append(eventID)
        let ok = deleteResults[eventID] ?? nextDeleteResult
        if mirrorsWrites, ok { eventsValue.removeAll { $0.id == eventID } }
        return ok
    }

    package func readableCalendars() -> [CalendarChoice] {
        readableCalls += 1
        return readable ?? choices
    }

    package func events(from start: Date, to end: Date, calendarIDs: [String]) -> [CalendarEventInfo] {
        eventReads.append(DateInterval(start: start, end: max(start, end)))
        return eventsValue
            .filter { calendarIDs.contains($0.calendarID) && $0.start < end && $0.end > start }
            .sorted { $0.start < $1.start }
    }

    private func info(_ id: String, _ draft: CalendarEventDraft) -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: draft.title, start: draft.start, end: draft.end, calendarID: draft.calendarID)
    }
}
