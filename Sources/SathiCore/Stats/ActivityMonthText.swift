import Foundation

package enum ActivityMonthText {
    package static func make(_ days: [ActivityDay], month: MonthKey, calendar: Calendar) -> String {
        ActivityRangeText.make(days, title: Copywriter.trackerMonthTitle(month.start(in: calendar), calendar: calendar), calendar: calendar)
    }
}
