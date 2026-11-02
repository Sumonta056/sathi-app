import AppKit
import EventKit
import SathiCore

@MainActor
package final class EventKitCalendarWriter: CalendarWriter {
    private lazy var store = EKEventStore()

    package init() {}

    package var access: CalendarAccess {
        let status = EKEventStore.authorizationStatus(for: .event)
        let granted: Bool = if #available(macOS 14, *) {
            status == .fullAccess
        } else {
            status == .authorized
        }
        return CalendarMapping.access(notDetermined: status == .notDetermined, granted: granted)
    }

    package func requestAccess() async -> CalendarAccess {
        do {
            if #available(macOS 14, *) {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestAccess(to: .event)
            }
        } catch {
            return access
        }
        return access
    }

    package func calendars() -> [CalendarChoice] {
        guard access == .allowed else { return [] }
        let choices = store.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map { calendar in
                CalendarChoice(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    account: calendar.source?.title ?? "",
                    colorHex: Self.hex(of: calendar.cgColor)
                )
            }
        return CalendarMapping.sorted(choices)
    }

    package func defaultCalendarID() -> String? {
        guard access == .allowed, let calendar = store.defaultCalendarForNewEvents, calendar.allowsContentModifications else {
            return nil
        }
        return calendar.calendarIdentifier
    }

    package func save(_ draft: CalendarEventDraft) -> CalendarSaveResult {
        guard let calendar = writableCalendar(draft.calendarID) else { return .calendarMissing }
        let event = EKEvent(eventStore: store)
        apply(draft, calendar: calendar, to: event)
        return commit(event)
    }

    package func update(eventID: String, draft: CalendarEventDraft) -> CalendarSaveResult {
        guard access == .allowed,
              let event = store.event(withIdentifier: eventID),
              let calendar = writableCalendar(draft.calendarID) else { return .calendarMissing }
        apply(draft, calendar: calendar, to: event)
        return commit(event)
    }

    private func writableCalendar(_ id: String) -> EKCalendar? {
        guard access == .allowed,
              let calendar = store.calendar(withIdentifier: id),
              calendar.allowsContentModifications else { return nil }
        return calendar
    }

    private func apply(_ draft: CalendarEventDraft, calendar: EKCalendar, to event: EKEvent) {
        event.title = draft.title
        event.calendar = calendar
        event.startDate = draft.start
        event.endDate = draft.end
    }

    private func commit(_ event: EKEvent) -> CalendarSaveResult {
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            return .failed
        }
        guard let id = event.eventIdentifier else { return .failed }
        return .saved(eventID: id)
    }

    private static func hex(of color: CGColor?) -> UInt32 {
        guard let color,
              let srgb = NSColor(cgColor: color)?.usingColorSpace(.sRGB) else { return 0 }
        return CalendarMapping.hex(
            red: Double(srgb.redComponent),
            green: Double(srgb.greenComponent),
            blue: Double(srgb.blueComponent)
        )
    }
}
