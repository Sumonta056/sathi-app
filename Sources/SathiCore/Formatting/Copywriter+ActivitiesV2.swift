import Foundation

extension Copywriter {
    package static let activitiesNoData = "\u{2014}"
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

    package static func activitiesLength(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds / Timing.minute))
        let h = total / Limits.minutesPerHour
        let m = total % Limits.minutesPerHour
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    package static func activitiesTableSummary(_ categories: Int) -> String {
        "logged · \(categories) " + (categories == 1 ? "category" : "categories")
    }

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
