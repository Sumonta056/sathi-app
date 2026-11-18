import Foundation

extension Engine {
    package func calendarPage(_ range: CalendarPageRange, metrics: CalendarLayoutMetrics) -> CalendarPageData {
        var page = calendarPage(range)
        guard range.kind != .month else { return page }
        page.grid = CalendarSplitLayout.layout(
            page.blocks, days: range.days, calendar: calendar,
            rowMinutes: data.prefs.calendarPage.rowMinutes, metrics: metrics
        )
        return page
    }
}
