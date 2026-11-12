import Foundation

package struct ReportsOverviewBuilder: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar) {
        self.calendar = .gregorian(in: calendar.timeZone)
    }

    package func build(
        range: StatsRange,
        judge: BuddyDayJudge,
        previous: BuddyDayJudge,
        previousDays: [Date],
        streak: Int
    ) -> ReportsOverview {
        let days = range.days.map(\.start)
        let isCurrent = range.holds(judge.now)
        let scores = HabitID.allCases.map { score($0, days: days, judge: judge) }
        let live = judge.buddies
        let met = scores.filter { live.contains($0.habit) }.reduce(0) { $0 + $1.met }
        let before = live.reduce(0) { sum, id in sum + previousDays.filter { previous.isMet(id, on: $0) }.count }
        let total = ReportsScore(
            met: met,
            possible: live.reduce(0) { sum, id in sum + days.filter { Self.isGoalDay(id, $0, judge) }.count },
            label: Copywriter.reportsScoreLabel(range.kind, daysSoFar: days.filter(judge.isPast).count, isCurrent: isCurrent),
            headline: Copywriter.reportsHeadline(range.kind, scores: scores.filter { live.contains($0.habit) }),
            changeText: Copywriter.reportsScoreChange(met - before, kind: range.kind, isCurrent: isCurrent, streak: streak),
            isUp: met > before
        )
        return ReportsOverview(
            scores: scores,
            score: total,
            columns: days.map { column($0, kind: range.kind, judge: judge) },
            rows: live.map { row($0, days: days, judge: judge) },
            streak: streak
        )
    }

    static func isGoalDay(_ id: HabitID, _ day: Date, _ judge: BuddyDayJudge) -> Bool {
        judge.isPast(day) ? judge.isCounted(id, on: day) : judge.isOn(id, on: day)
    }

    private func score(_ id: HabitID, days: [Date], judge: BuddyDayJudge) -> BuddyScore {
        let isLive = judge.buddies.contains(id)
        return BuddyScore(
            habit: id,
            met: isLive ? days.filter { judge.isPast($0) && judge.isMet(id, on: $0) }.count : 0,
            days: days.count,
            counted: isLive ? days.filter { judge.isCounted(id, on: $0) }.count : 0,
            isOff: !isLive
        )
    }

    private func column(_ day: Date, kind: ReportRange, judge: BuddyDayJudge) -> DayColumn {
        DayColumn(
            date: day,
            label: Copywriter.reportsDayColumn(day, kind: kind, zone: calendar.timeZone),
            isToday: calendar.isDate(day, inSameDayAs: judge.now),
            isFuture: !judge.isPast(day)
        )
    }

    private func row(_ id: HabitID, days: [Date], judge: BuddyDayJudge) -> BuddyDayRow {
        BuddyDayRow(habit: id, cells: days.map { day in
            let state = judge.state(id, on: day)
            let text: String = switch state {
            case .future: ""
            case .off: Copywriter.reportsOffCell
            case .met, .some, .none: Copywriter.reportsShortAmount(id, judge.total(id, on: day))
            }
            return BuddyDayCell(day: day, text: text, state: state)
        })
    }
}
