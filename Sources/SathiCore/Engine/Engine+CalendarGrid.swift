import Foundation

extension Engine {
    package func calendarPage(_ range: CalendarPageRange, metrics: CalendarLayoutMetrics) -> CalendarPageData {
        var page = calendarPageBase(range)
        guard range.kind != .month else { return page }
        var shaped = metrics
        shaped.foldsNights = range.kind == .week
        page.grid = CalendarSplitLayout.layout(
            page.blocks, days: range.days, calendar: calendar,
            rowMinutes: data.prefs.calendarPage.rowMinutes, metrics: shaped, now: clock.now
        )
        return page
    }
}
