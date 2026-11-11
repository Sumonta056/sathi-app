import Foundation

package struct StreakMonthBuilder: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar) {
        self.calendar = .gregorian(in: calendar.timeZone)
    }

    package func overview(_ month: StatsRange, judge: BuddyDayJudge, streak: Int) -> OverviewMonth {
        let live = judge.buddies
        let days = month.days.map(\.start).enumerated().map { index, day in
            OverviewDay(
                day: index + 1,
                dots: HabitID.allCases.map { BuddyDot(habit: $0, isMet: live.contains($0) && judge.isMet($0, on: day)) },
                isStreakDay: judge.isStreakDay(day) == true,
                isToday: calendar.isDate(day, inSameDayAs: judge.now),
                isFuture: !judge.isPast(day)
            )
        }
        return OverviewMonth(
            title: Copywriter.rangeDate(month.interval.start, "MMMM yyyy", calendar.timeZone),
            streakText: Copywriter.reportsStreak(streak),
            leadingBlanks: leadingBlanks(month),
            days: days,
            canGoForward: month.canGoForward(now: judge.now)
        )
    }

    package func buddy(_ id: HabitID, month: StatsRange, judge: BuddyDayJudge) -> BuddyMonth {
        let days = month.days.map(\.start)
        let cells = days.enumerated().map { index, day in
            BuddyMonthCell(day: index + 1, state: judge.state(id, on: day), isToday: calendar.isDate(day, inSameDayAs: judge.now))
        }
        return BuddyMonth(
            habit: id,
            title: Copywriter.reportsBuddyMonthTitle(id, month: month.interval.start, zone: calendar.timeZone),
            goalDaysText: Copywriter.reportsGoalDayCount(cells.filter { $0.state == .met }.count),
            leadingBlanks: leadingBlanks(month),
            cells: cells,
            canGoForward: month.canGoForward(now: judge.now)
        )
    }

    private func leadingBlanks(_ month: StatsRange) -> Int {
        let weekday = calendar.component(.weekday, from: month.interval.start)
        return (weekday - Limits.weekStartWeekday + Limits.daysPerWeek) % Limits.daysPerWeek
    }
}
