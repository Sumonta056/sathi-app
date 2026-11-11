import Foundation

extension Engine {
    package func reportsOverview(_ range: StatsRange) -> ReportsOverview {
        let now = clock.now
        let cut = range.comparable(now: now, calendar: calendar)
        let previousDays = range.previous.days.map(\.start).filter { $0 < cut.end }
        return ReportsOverviewBuilder(calendar: calendar).build(
            range: range,
            judge: dayJudge(range.interval),
            previous: dayJudge(cut),
            previousDays: previousDays,
            streak: allBuddiesStreak()
        )
    }

    package func buddyTab(_ range: StatsRange, habit: HabitID) -> BuddyTabReport {
        let report = ReportScreenBuilder.habitReport(habit, in: report(range))
        let change = buddyRange(range).totals.first { $0.habit == habit }?.change ?? .none
        return BuddyTabBuilder(calendar: calendar).build(
            habit,
            range: range,
            judge: dayJudge(range.interval),
            parts: BuddyTabParts(
                chart: ReportScreenBuilder(calendar: calendar).chart(range.kind, habit: report),
                change: change,
                streak: streak(habit)
            )
        )
    }

    package func streakOverview(_ month: StatsRange) -> OverviewMonth {
        StreakMonthBuilder(calendar: calendar).overview(month, judge: dayJudge(month.interval), streak: allBuddiesStreak())
    }

    package func buddyMonth(_ month: StatsRange, habit: HabitID) -> BuddyMonth {
        StreakMonthBuilder(calendar: calendar).buddy(habit, month: month, judge: dayJudge(month.interval))
    }

    package func allBuddiesStreak() -> Int {
        let resets = Dictionary(uniqueKeysWithValues: HabitID.allCases.compactMap { id in
            data.live.streakReset[id.rawValue].map { (id, $0) }
        })
        return AllBuddiesStreak.current(now: clock.now, calendar: calendar) { month in
            dayJudge(month, resets: resets)
        }
    }

    func dayJudge(_ span: DateInterval, resets: [HabitID: Date] = [:]) -> BuddyDayJudge {
        BuddyDayJudge(calendar: calendar, prefs: data.prefs, now: clock.now, events: rangeEvents(span), resets: resets)
    }
}
