import Foundation

extension Copywriter {
    package static let calendarHoverChildren = "Done in this event"
    package static let calendarHoverAlsoHere = "Also here"
    package static let calendarHoverMetaSeparator = " · "
    package static let calendarHoverGroupMembers = "In this block"
    package static let calendarGroupDetailSeparator = " · "
    package static let calendarGroupCategorySeparator = ", "

    package static func calendarHoverGroupKind(_ count: Int) -> String {
        "\(count) activities · grouped"
    }

    package static func calendarGroupTitle(_ count: Int) -> String {
        "\(count) activities"
    }

    package static func calendarInside(_ count: Int) -> String {
        "\(count) inside"
    }

    package static func calendarHoverKind(_ k: CalendarHoverKind) -> String {
        switch k {
        case .event: return "Calendar event · Plan"
        case .activity: return "Activity · Actual"
        case .todo: return "To-do · Apple Reminders"
        case .away: return trackerAway
        case .group: return calendarGroupTitle(0)
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
        case .selectAll: return "Select all"
        }
    }
}
