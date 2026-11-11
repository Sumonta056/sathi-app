import Foundation

extension Engine {
    package func buddyRange(_ range: StatsRange) -> (totals: [BuddyRangeTotal], bars: [GoalDayBar]) {
        let now = clock.now
        return BuddyRangeBuilder(calendar: calendar).build(
            range: range,
            now: now,
            events: rangeEvents(range.interval),
            previousEvents: rangeEvents(range.comparable(now: now, calendar: calendar)),
            prefs: data.prefs
        )
    }

    package func report(_ range: StatsRange) -> Report {
        ReportBuilder(calendar: calendar).build(
            range, now: clock.now, events: rangeEvents(range.interval), prefs: data.prefs
        )
    }

    package func reportScreen(_ range: StatsRange, selected: HabitID) -> ReportScreen {
        let enabled = enabledHabits(data.prefs)
        let habit = ReportScreenBuilder.resolve(selected, enabled: enabled)
        let month = StatsRange.containing(clock.now, kind: .month, calendar: calendar)
        return ReportScreenBuilder(calendar: calendar).build(ReportScreenInput(
            range: range.kind,
            selected: selected,
            report: report(range),
            month: report(month),
            enabled: enabled,
            streak: streak(habit),
            longest: longestStreak(habit),
            now: clock.now
        ))
    }

    func rangeEvents(_ span: DateInterval) -> [HistoryEvent] {
        let windowStart = Self.windowStart(now: clock.now, calendar: calendar)
        let older = span.start < windowStart
            ? storedEvents(from: span.start, to: min(span.end, windowStart)) : []
        let recent = data.events.filter { max(span.start, windowStart) <= $0.date && $0.date < span.end }
        return older + recent
    }
}
