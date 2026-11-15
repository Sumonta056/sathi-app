import AppKit
import EventKit
import SathiCore

@MainActor
package final class EventKitTodoStore: TodoStore {
    private let writer: EventKitCalendarWriter
    package private(set) var revision = 0

    package init(writer: EventKitCalendarWriter) {
        self.writer = writer
    }

    var store: EKEventStore { writer.store }

    package var access: TodoAccess {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        let granted: Bool = if #available(macOS 14, *) {
            status == .fullAccess
        } else {
            status == .authorized
        }
        return TodoMapping.access(notDetermined: status == .notDetermined, granted: granted)
    }

    package func requestAccess() async -> TodoAccess {
        let before = access
        do {
            if #available(macOS 14, *) {
                _ = try await store.requestFullAccessToReminders()
            } else {
                _ = try await store.requestAccess(to: .reminder)
            }
        } catch {
            return access
        }
        let after = access
        if before == .notAsked, after == .allowed {
            store.reset()
            revision += 1
        }
        return after
    }

    package func accounts() -> [TodoAccount] {
        guard access == .allowed else { return [] }
        let defaultSource = store.defaultCalendarForNewReminders()?.source?.sourceIdentifier
        var seen = Set<String>()
        return store.calendars(for: .reminder).compactMap(\.source).compactMap { source in
            guard seen.insert(source.sourceIdentifier).inserted else { return nil }
            return TodoAccount(
                id: source.sourceIdentifier,
                name: source.title,
                allowsNewLists: source.sourceType != .birthdays && source.sourceType != .subscribed,
                isICloud: source.sourceType == .calDAV && source.sourceIdentifier == defaultSource
            )
        }
    }

    package func lists() -> [TodoList] {
        guard access == .allowed else { return [] }
        return TodoMapping.sorted(store.calendars(for: .reminder).map(Self.list))
    }

    package func todos(listIDs: Set<String>, completedSince: Date) async -> [Todo] {
        guard access == .allowed else { return [] }
        let calendars = store.calendars(for: .reminder).filter { listIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let open = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        let done = store.predicateForCompletedReminders(withCompletionDateStarting: completedSince, ending: nil, calendars: calendars)
        let cal = Calendar.current
        let first = await fetch(open, calendar: cal)
        let second = await fetch(done, calendar: cal)
        return first + second
    }

    func didWrite(_ result: TodoWriteResult) -> TodoWriteResult {
        if case .done = result { revision += 1 }
        return result
    }

    func reminder(_ id: String) -> EKReminder? {
        guard access == .allowed else { return nil }
        return store.calendarItem(withIdentifier: id) as? EKReminder
    }

    func writableList(_ id: String) -> EKCalendar? {
        guard access == .allowed,
              let calendar = store.calendar(withIdentifier: id),
              calendar.allowsContentModifications else { return nil }
        return calendar
    }

    private func fetch(_ predicate: NSPredicate, calendar: Calendar) async -> [Todo] {
        await withCheckedContinuation { (c: CheckedContinuation<[Todo], Never>) in
            store.fetchReminders(matching: predicate) { items in
                c.resume(returning: (items ?? []).map { Self.todo($0, calendar: calendar) })
            }
        }
    }

    nonisolated static func todo(_ r: EKReminder, calendar: Calendar) -> Todo {
        Todo(
            id: r.calendarItemIdentifier,
            listID: r.calendar?.calendarIdentifier ?? "",
            title: r.title ?? "",
            notes: r.notes ?? "",
            due: r.dueDateComponents.flatMap { TodoMapping.due(from: $0, calendar: calendar) },
            priority: r.priority,
            isDone: r.isCompleted,
            doneAt: r.completionDate,
            createdAt: r.creationDate ?? .distantPast,
            repeats: r.hasRecurrenceRules,
            url: r.url
        )
    }

    static func list(_ c: EKCalendar) -> TodoList {
        let rgb = c.cgColor.flatMap { NSColor(cgColor: $0)?.usingColorSpace(.sRGB) }
        return TodoList(
            id: c.calendarIdentifier,
            name: c.title,
            colorHex: TodoMapping.colorHex(
                red: Double(rgb?.redComponent ?? 0),
                green: Double(rgb?.greenComponent ?? 0),
                blue: Double(rgb?.blueComponent ?? 0)
            ),
            accountID: c.source?.sourceIdentifier ?? "",
            accountName: c.source?.title ?? "",
            canEdit: c.allowsContentModifications
        )
    }
}
