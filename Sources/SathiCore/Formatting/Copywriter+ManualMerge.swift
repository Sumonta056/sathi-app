import Foundation

extension Copywriter {
    package static let mergeButton = "Merge"
    package static let mergeCalendarFailed = "The calendar did not change, so Sathi did not merge."
    package static let mergeCalendarPartly = "Sathi did not merge. Some calendar events may have changed; check the calendar."
    package static let mergeUndo = "Undo"
    package static let mergeUndoCalendarFailed = "The rows are back, but the calendar could not be put back."

    package static func mergeBlocked(_ block: ManualMergeBlock) -> String {
        switch block {
        case .tooFew: "Pick 2 or more activities to merge."
        case .notStored: "Only saved activities can merge."
        case .differentDays: "Activities from 2 days cannot merge."
        case .eventRow: "A calendar event row cannot merge."
        case .buddyRow: "A buddy session cannot merge."
        case .timeBlockRow: "A time block cannot merge."
        case .namedAway: "An Away with a place is in the way."
        case .rowBetween: "Another activity sits between them."
        }
    }

    package static func mergeSelectLabel(_ title: String) -> String { "Select \(title)" }

    package static func mergePreview(count: Int, start: Date, end: Date, calendar: Calendar) -> String {
        "\(count) rows become 1, \(quickClock(start, calendar: calendar)) to \(quickClock(end, calendar: calendar))"
    }
}
