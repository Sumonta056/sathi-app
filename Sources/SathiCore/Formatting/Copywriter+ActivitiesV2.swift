import Foundation

extension Copywriter {
    package static let activitiesTileLogged = "Total logged"
    package static let activitiesTileFocus = "Focus work"
    package static let activitiesTileAway = "Away"
    package static let activitiesTileCount = "Activities"
    package static let activitiesTimeline = "Timeline"
    package static let activitiesAdd = "+ Add activity"
    package static let activitiesEditTitle = "Edit activity"
    package static let activitiesAddTitle = "Add activity"
    package static let activitiesFieldName = "NAME"
    package static let activitiesFieldStart = "START"
    package static let activitiesFieldEnd = "END"
    package static let activitiesFieldLength = "LENGTH"
    package static let activitiesFieldCategory = "CATEGORY"
    package static let activitiesFieldPlace = "PLACE"
    package static let activitiesFieldCalendar = "CALENDAR"
    package static let activitiesSetsEnd = "sets the end"
    package static let activitiesNoCategory = "None"
    package static let activitiesNoCalendar = "Do not add"
    package static let activitiesClose = "Close"
    package static let activitiesFillGap = "Fill this gap"
    package static let activitiesCalendarUnchanged = "Saved, but the calendar did not change. Check calendar access."
    package static let activitiesCalendarFailed = "Saved, but the old calendar event could not be removed. Check calendar access."
    package static let activitiesCurrentCalendar = "Current calendar"
    package static let activitiesDeleteFailed = "Sathi could not delete the calendar event, so the activity stays. Try again."

    package static func activitiesLength(_ seconds: TimeInterval) -> String { categoryTableHours(seconds) }

    package static func activitiesLoggedNote(_ change: RangeChange, kind: ReportRange) -> String {
        rangeChange(change, kind: kind) { activitiesLength($0) }
    }

    package static func activitiesFocusNote(_ percent: Int?) -> String {
        percent.map { "\($0)% of the day" } ?? ""
    }

    package static func activitiesAwayNote(_ count: Int, place: String?) -> String {
        guard count > 0 else { return "" }
        let times = "\(count) " + (count == 1 ? "time" : "times")
        return place.map { times + " · " + $0 } ?? times
    }

    package static func activitiesTopNote(_ category: String?) -> String {
        category.map { "Top: " + $0 } ?? ""
    }

    package static func activitiesCountLine(_ activities: Int, gaps: Int) -> String {
        let line = "\(activities) " + (activities == 1 ? "activity" : "activities")
        guard gaps > 0 else { return line }
        return line + " · \(gaps) " + (gaps == 1 ? "gap" : "gaps")
    }

    package static func activitiesGap(_ span: String) -> String {
        trackerNotLogged + " · " + span
    }

    package static func activitiesEditLabel(_ title: String) -> String {
        "Edit " + title
    }
}
