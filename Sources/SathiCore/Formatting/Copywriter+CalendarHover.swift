import Foundation

extension Copywriter {
    package static let calendarHoverChildren = "Done in this event"
    package static let calendarHoverAlsoHere = "Also here"
    package static let calendarHoverMetaSeparator = " · "

    package static func calendarHoverKind(_ k: CalendarHoverKind) -> String {
        switch k {
        case .event: return "Calendar event · Plan"
        case .activity: return "Activity · Actual"
        case .todo: return "To-do · Apple Reminders"
        case .away: return trackerAway
        }
    }

    package static func calendarHoverAction(_ a: CalendarHoverAction) -> String {
        switch a {
        case .startAsActivity: return "Start as activity"
        case .edit: return "Edit"
        case .openInCalendar: return "Open in Calendar"
        case .merge: return "Merge"
        case .delete: return "Delete"
        case .markDone: return calendarTodoMarkDone
        case .openInReminders: return "Open in Reminders"
        case .editAway: return "Edit Away"
        }
    }
}
