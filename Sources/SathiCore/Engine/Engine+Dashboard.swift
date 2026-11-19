import Foundation

extension Engine {
    package var dashboardScore: DashboardScore? {
        dashboardScore(.containing(clock.now, kind: .day, calendar: calendar))
    }

    package var dashboardDateLine: String {
        Copywriter.todayDateLine(clock.now, calendar: calendar)
    }

    package func dashboardScore(_ range: StatsRange) -> DashboardScore? {
        let today = range.interval.start
        let judge = dayJudge(range.interval)
        let live = judge.buddies
        guard !live.isEmpty else { return nil }
        let cut = range.comparable(now: clock.now, calendar: calendar)
        let previous = dayJudge(cut)
        let yesterday = range.previous.interval.start
        let met = live.filter { judge.isPast(today) && judge.isMet($0, on: today) }.count
        let before = live.filter { previous.isMet($0, on: yesterday) }.count
        let hasData = live.contains { judge.total($0, on: today) > 0 || previous.total($0, on: yesterday) > 0 }
        let change = RangeChange(current: Double(met), previous: Double(before), hasData: hasData)
        return DashboardScore(
            met: met,
            possible: live.filter { ReportsOverviewBuilder.isGoalDay($0, today, judge) }.count,
            changeText: Copywriter.rangeChange(change, kind: .day) { String(Int($0)) },
            isUp: met > before
        )
    }
}
