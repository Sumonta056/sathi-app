import Foundation

package enum ActivityRangeText {
    package static func make(_ days: [ActivityDay], title: String, calendar: Calendar) -> String {
        let stats = ActivityMonthStats(days)
        var lines = [
            Copywriter.trackerRangeHeader(title: title, days: stats.daysTracked, realWork: stats.realWork),
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
