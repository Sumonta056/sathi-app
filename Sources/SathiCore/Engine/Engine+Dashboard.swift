import Foundation

extension Engine {
    package var dashboardScore: DashboardScore? {
        let range = StatsRange.containing(clock.now, kind: .day, calendar: calendar)
        return dashboardScore(range, overview: reportsOverview(range), yesterday: dashboardYesterday(range))
    }

    package func dashboardScore(_ range: StatsRange, overview: ReportsOverview, yesterday: DashboardYesterday) -> DashboardScore? {
        guard !overview.rows.isEmpty else { return nil }
        let cut = range.comparable(now: clock.now, calendar: calendar).end
        let met = overview.score.met
        let before = yesterday.metAt.filter { $0 < cut }.count
        let today = overview.rows.contains { row in row.cells.contains { $0.state == .met || $0.state == .some } }
        let hasData = today || (yesterday.firstProgress.map { $0 < cut } ?? false)
        let change = RangeChange(current: Double(met), previous: Double(before), hasData: hasData)
        return DashboardScore(
            met: met,
            possible: overview.score.possible,
            changeText: Copywriter.rangeChange(change, kind: .day) { String(Int($0)) },
            isUp: met > before
        )
    }

    package func dashboardYesterday(_ range: StatsRange) -> DashboardYesterday {
        let goals = BuddyDayJudge(calendar: calendar, prefs: data.prefs, now: clock.now, events: [])
        let live = Set(goals.buddies)
        let events = rangeEvents(range.previous.interval)
            .filter { $0.kind == .done && $0.amount > 0 && live.contains($0.habit) }
            .sorted { $0.date < $1.date }
        var sums: [HabitID: Double] = [:]
        var metAt: [HabitID: Date] = [:]
        for event in events where metAt[event.habit] == nil {
            sums[event.habit, default: 0] += event.amount
            if sums[event.habit, default: 0] >= goals.goal(event.habit) { metAt[event.habit] = event.date }
        }
        return DashboardYesterday(metAt: Array(metAt.values), firstProgress: events.first?.date)
    }
}
