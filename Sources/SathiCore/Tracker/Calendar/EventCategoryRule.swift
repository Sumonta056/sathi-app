import Foundation

package struct EventCategoryPick: Equatable, Sendable {
    package var name: String?
    package var added: ActivityCategory?

    package init(name: String?, added: ActivityCategory? = nil) {
        self.name = name
        self.added = added
    }
}

package enum EventCategoryRule {
    package static func pick(for e: CalendarEventInfo, prefs: TrackerPrefs, calendars: [CalendarChoice]) -> EventCategoryPick {
        let names = Set(prefs.categories.map(\.name))
        if let title = prefs.eventCategoryByTitle[e.title], names.contains(title) {
            return EventCategoryPick(name: title)
        }
        if let mapped = prefs.categoryByCalendar[e.calendarID], names.contains(mapped) {
            return EventCategoryPick(name: mapped)
        }
        guard let cal = calendars.first(where: { $0.id == e.calendarID }),
              let name = ActivityCategoryList.cleanName(cal.title) else { return EventCategoryPick(name: nil) }
        if let known = prefs.categories.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return EventCategoryPick(name: known.name)
        }
        return EventCategoryPick(name: name, added: ActivityCategory(name: name, colorHex: cal.colorHex))
    }
}
