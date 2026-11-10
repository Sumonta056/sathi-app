import Foundation

package enum ActivityStandupText {
    package static func make(_ day: ActivityDay, calendar: Calendar) -> String {
        let stats = ActivityDayStats(day)
        let date = day.day.start(in: calendar)
        var lines = [Copywriter.trackerStandupHeader(date, realWork: stats.realWork, calendar: calendar)]
        for row in ActivityTextTotals.grouped(stats.segments) {
            lines.append(Copywriter.trackerStandupLine(text: row.text, category: row.category, length: row.seconds))
        }
        return lines.joined(separator: "\n")
    }
}
