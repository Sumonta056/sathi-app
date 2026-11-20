import SathiCore
import SwiftUI

struct ActivityEditPanel: View {
    let day: ActivityDay
    let target: ActivityEditTarget
    let categories: [ActivityCategory]
    let calendar: Calendar
    let calendars: [CalendarChoice]
    let calendarNames: [String: String]
    var places: [String] = []
    let actions: ActivityDayActions
    @Binding var editing: ActivityEditTarget?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if let section {
                section.id(target.key).padding(.bottom, UIMetrics.reportsGap)
            }
        }
    }

    static func shows(_ target: ActivityEditTarget, in day: ActivityDay) -> Bool {
        switch target {
        case let .activity(id): return day.activities.contains { $0.id == id }
        case let .add(span): return day.hours.contains(span.start)
        }
    }

    private var section: ActivityEditSection? {
        let dayStart = day.day.start(in: calendar)
        switch target {
        case let .activity(id):
            guard let a = day.activities.first(where: { $0.id == id }) else { return nil }
            return ActivityEditSection(
                draft: ActivityEditDraft(a, calendar: calendar, writable: calendars.map(\.id)), title: Copywriter.activitiesEditTitle,
                accent: a.kind == .away ? Night.chipText : ActivityColors.color(a.category, in: categories),
                categories: categories, calendars: calendars, places: places, calendarNames: calendarNames,
                dayStart: dayStart, calendar: calendar, save: { actions.edit(id, $0) },
                delete: {
                    guard actions.delete(id) else { return false }
                    editing = nil
                    return true
                },
                close: { editing = nil }
            )
        case let .add(span):
            return ActivityEditSection(
                draft: ActivityEditDraft(start: span.start, end: span.end, calendar: calendar), title: Copywriter.activitiesAddTitle,
                accent: Night.tracker, categories: categories, calendars: calendars, calendarNames: calendarNames,
                dayStart: dayStart, calendar: calendar, save: { actions.add($0) }, delete: nil, close: { editing = nil }
            )
        }
    }
}
