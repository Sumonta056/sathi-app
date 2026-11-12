import Foundation

package struct BuddyRangeBuilder: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func build(
        range: StatsRange,
        now: Date,
        events: [HistoryEvent],
        previousEvents: [HistoryEvent],
        prefs: Prefs
    ) -> (totals: [BuddyRangeTotal], bars: [GoalDayBar]) {
        let cut = range.comparable(now: now, calendar: calendar)
        let inside = events.filter { range.holds($0.date) }
        let before = previousEvents.filter { cut.start <= $0.date && $0.date < cut.end }
        let days = range.days
        let pastDays = days.filter { $0.start <= now }
        let totals = HabitID.allCases.map { id in
            total(id, prefs: prefs, events: inside, previous: before, days: pastDays)
        }
        let bars = days.map { bar($0, prefs: prefs, now: now, events: inside) }
        return (totals, bars)
    }

    private func total(
        _ id: HabitID,
        prefs: Prefs,
        events: [HistoryEvent],
        previous: [HistoryEvent],
        days: [DateInterval]
    ) -> BuddyRangeTotal {
        let goal = id.rules(prefs, calendar: calendar).dailyGoal
        let schedule = prefs.days(id)
        let stats = Stats(calendar: calendar)
        let done = { (list: [HistoryEvent]) in list.filter { $0.habit == id && $0.kind == .done } }
        let sum = { (list: [HistoryEvent]) in done(list).reduce(0) { $0 + $1.amount } }
        let counted = days.filter { day in
            let met = goal > 0 && stats.total(id, on: day.start, in: events) >= goal
            return met || schedule.isOn(day.start, calendar: calendar)
        }
        let met = goal > 0 ? counted.filter { stats.total(id, on: $0.start, in: events) >= goal }.count : 0
        let current = sum(events)
        return BuddyRangeTotal(
            habit: id,
            total: current,
            change: RangeChange(current: current, previous: sum(previous), hasData: !done(previous).isEmpty),
            daysMet: met,
            daysCounted: counted.count,
            isOff: !prefs.isEnabled(id)
        )
    }

    private func bar(_ day: DateInterval, prefs: Prefs, now: Date, events: [HistoryEvent]) -> GoalDayBar {
        let stats = Stats(calendar: calendar)
        var met = 0
        var of = 0
        for id in HabitID.allCases where prefs.isEnabled(id) {
            let goal = id.rules(prefs, calendar: calendar).dailyGoal
            guard goal > 0 else { continue }
            let reached = stats.total(id, on: day.start, in: events) >= goal
            guard reached || prefs.days(id).isOn(day.start, calendar: calendar) else { continue }
            of += 1
            met += reached ? 1 : 0
        }
        return GoalDayBar(day: day.start, met: met, of: of, isFuture: day.start > now)
    }
}
