import Foundation

package enum ActivityMonthText {
    package static func make(_ days: [ActivityDay], month: MonthKey, calendar: Calendar) -> String {
        let stats = ActivityMonthStats(days)
        var lines = [
            Copywriter.trackerMonthHeader(
                month.start(in: calendar), days: stats.daysTracked, realWork: stats.realWork, calendar: calendar
            ),
            Copywriter.trackerMonthAverage(stats.averageDay)
        ]
        for c in stats.categories {
            lines.append(Copywriter.trackerMonthCategoryLine(category: c.name, length: c.seconds, percent: c.percent))
        }
        for row in stats.rows {
            lines.append(Copywriter.trackerMonthDayLine(
                row.day.start(in: calendar), realWork: row.realWork, texts: row.topTexts, calendar: calendar
            ))
        }
        return lines.joined(separator: "\n")
    }
}
