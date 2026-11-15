import Foundation

extension Copywriter {
    package static let mainPageTodos = "To-dos"
    package static let todoRepeats = "Repeats"
    package static let todoNewList = "New list"
    package static let todoRenameList = "Rename list"
    package static let todoEmptyList = "Nothing here"
    package static let todoHideCompleted = "Hide completed"
    package static let todoNoDate = "No date"
    package static let todoMoveFailed = "Saved, but Sathi could not move it to the other list."
    package static let todoSaveFailed = "Sathi could not save this to-do."
    package static let todoDeleteFailed = "Sathi could not delete this to-do."
    package static let todoMarkDone = "Mark done"
    package static let todoMarkNotDone = "Mark not done"
    package static let todoNewPlaceholder = "New to-do"
    package static let todoAdd = "Add"
    package static let todoNotes = "Notes"
    package static let todoDue = "Due"
    package static let todoList = "List"
    package static let todoAddTime = "Add time"
    package static let todoNoTime = "No time"
    package static let todoDueMarked = "Due date"
    package static let todoSave = "Save"
    package static let todoCancel = "Cancel"
    package static let todoDelete = "Delete"
    package static let todoKeep = "Keep"
    package static let todoEditing = "Editing"
    package static let todoListName = "Name"
    package static let todoListColor = "Color"
    package static let todoListAccount = "Account"
    package static let todoCreate = "Create"
    package static let todoRename = "Rename"
    package static let todoListFormHint = "Delete a list in Apple Reminders."
    package static let todoGateTitle = "Your Apple Reminders, in Sathi"
    package static let todoGateNotAsked = "Sathi needs access to Reminders to show your to-dos."
    package static let todoGateDenied = "Reminders access is off. Turn it on in System Settings."
    package static let todosSettingsSubtitle =
        "Shows your Apple Reminders in Sathi. Every change goes back to Reminders and to your iPhone. Sathi keeps no copy."
    package static let todosSettingsOnLabel = "Show Apple Reminders"
    package static let todosSettingsAllowed = "Access to Reminders is on"
    package static let todosSettingsNotAsked = "Sathi has not asked yet"
    package static let todosSettingsDenied = "Access is off"
    package static let todosSettingsAccess = "Reminders access"
    package static let todosSettingsShownLists = "Shown lists"
    package static let todosSettingsAskWhenDue = "Ask when due"
    package static let todosSettingsAskWhenDueHint = "Ask in the activity prompt when a to-do with a time is due"

    package static func todoDueText(_ due: TodoDue, now: Date, calendar: Calendar) -> String {
        let word = todoDayWord(due.date, now: now, calendar: calendar)
        guard due.hasTime else { return word }
        let c = calendar.dateComponents([.hour, .minute], from: due.date)
        return word + " · " + Fmt.timeOfDay((c.hour ?? 0) * 60 + (c.minute ?? 0), calendar: calendar)
    }

    package static func todoPriorityText(_ p: Int) -> String? {
        switch p {
        case 1 ... 4: "High"
        case 5: "Medium"
        case 6 ... 9: "Low"
        default: nil
        }
    }

    package static func todoDeleteConfirm(_ title: String) -> String { "Delete “\(title)”?" }

    private static func todoDayWord(_ date: Date, now: Date, calendar: Calendar) -> String {
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: date)
        switch calendar.dateComponents([.day], from: from, to: to).day ?? 0 {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default:
            var style = Date.FormatStyle().weekday(.abbreviated).day().month(.abbreviated)
            style.timeZone = calendar.timeZone
            return date.formatted(style)
        }
    }
}
