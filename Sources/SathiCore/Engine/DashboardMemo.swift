import Foundation

@MainActor
package final class DashboardMemo {
    private let yesterday = RangeMemo<StatsRange, DashboardYesterday>()
    private var date: (day: Date, line: String)?

    package init() {}

    package func score(_ range: StatsRange, overview: ReportsOverview, engine: Engine) -> DashboardScore? {
        score(range, overview: overview, engine: engine) { $0.dashboardYesterday($1) }
    }

    package func score(
        _ range: StatsRange,
        overview: ReportsOverview,
        engine: Engine,
        build: (Engine, StatsRange) -> DashboardYesterday
    ) -> DashboardScore? {
        let past = yesterday.value(range, end: range.interval.start, engine: engine, build: build)
        return engine.dashboardScore(range, overview: overview, yesterday: past)
    }

    package func dateLine(engine: Engine) -> String {
        let now = engine.clock.now
        let today = engine.calendar.startOfDay(for: now)
        if let date, date.day == today { return date.line }
        let line = Copywriter.todayDateLine(now, calendar: engine.calendar)
        date = (today, line)
        return line
    }
}
