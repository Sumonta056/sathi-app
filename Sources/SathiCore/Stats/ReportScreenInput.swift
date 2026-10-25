import Foundation

package struct ReportScreenInput: Sendable {
    package var range: ReportRange
    package var selected: HabitID
    package var report: Report
    package var month: Report
    package var enabled: Set<HabitID>
    package var streak: Int
    package var longest: Int
    package var now: Date

    package init(
        range: ReportRange,
        selected: HabitID,
        report: Report,
        month: Report,
        enabled: Set<HabitID>,
        streak: Int,
        longest: Int,
        now: Date
    ) {
        self.range = range
        self.selected = selected
        self.report = report
        self.month = month
        self.enabled = enabled
        self.streak = streak
        self.longest = longest
        self.now = now
    }
}
