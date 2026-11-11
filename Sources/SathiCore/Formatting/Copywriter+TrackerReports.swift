import Foundation

extension Copywriter {
    package static func trackerDaysTracked(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }

    package static let trackerTileRealWork = "REAL WORK"
    package static let trackerTileAway = "AWAY"
    package static let trackerTileAverageDay = "AVERAGE DAY"
    package static let trackerTileBestDay = "BEST DAY"
    package static let trackerFill = "Fill"
    package static let trackerDelete = "Delete"
    package static let trackerSave = "Save"
    package static let trackerCancel = "Cancel"
    package static let trackerNotInCalendar = "Not in calendar"
    package static let trackerCopied = "Copied."
    package static let trackerNoActivities = "No activities on this day."
    package static let trackerEditOverlap = "This time overlaps another activity."
    package static let trackerEditEmpty = "Type what you did."
    package static let trackerEditTooShort = "An activity needs at least 1 min."
    package static let trackerCopyForStandup = "Copy for standup"
    package static let trackerOpenFullReport = "Open full report"
    package static let trackerClose = "Close"
    package static let trackerCopiedStandup = "Copied. Paste it in your standup."
    package static let trackerFillInReport = "Fill it in the report"
    package static let trackerPlayAgain = "Play again"

    package static func trackerRealWork(_ seconds: TimeInterval) -> String { trackerDuration(seconds) + " of real work" }

    package static func trackerDayFacts(count: Int, away: TimeInterval, notLogged: TimeInterval) -> String {
        "\(count) activities · " + trackerDuration(away) + " Away · " + trackerDuration(notLogged) + " not logged"
    }

    package static func trackerShortDate(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle().weekday(.abbreviated).day().month(.abbreviated)
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    package static func trackerLongDate(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle().weekday(.wide).day().month(.wide)
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    package static func trackerYourDayEyebrow(_ date: Date, calendar: Calendar) -> String {
        "YOUR DAY · " + trackerLongDate(date, calendar: calendar).uppercased()
    }

    package static func trackerStandupHeader(_ date: Date, realWork: TimeInterval, calendar: Calendar) -> String {
        trackerShortDate(date, calendar: calendar) + " · " + trackerDuration(realWork)
    }

    package static func trackerStandupLine(text: String, category: String?, length: TimeInterval) -> String {
        "• " + text + (category.map { " (" + $0 + ")" } ?? "") + " · " + trackerDuration(length)
    }

    package static func trackerRangeHeader(title: String, days: Int, realWork: TimeInterval) -> String {
        title + " · \(days) days tracked · " + trackerDuration(realWork)
    }

    package static func trackerMonthAverage(_ seconds: TimeInterval) -> String { "Average " + trackerDuration(seconds) + " a day" }

    package static func trackerMonthCategoryLine(category: String, length: TimeInterval, percent: Int) -> String {
        category + " · " + trackerDuration(length) + " (\(percent)%)"
    }

    package static func trackerMonthDayLine(_ date: Date, realWork: TimeInterval, texts: [String], calendar: Calendar) -> String {
        trackerShortDate(date, calendar: calendar) + " · " + trackerTileDuration(realWork) + " · " + texts.joined(separator: ", ")
    }
}
