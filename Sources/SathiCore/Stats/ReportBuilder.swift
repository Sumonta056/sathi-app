import Foundation

package struct ReportBuilder: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = .gregorian(in: calendar.timeZone)
    }

    package func interval(_ range: ReportRange, containing now: Date) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        let start: Date
        let end: Date
        switch range {
        case .day:
            start = today
            end = calendar.nextDay(after: today)
        case .week:
            let weekday = calendar.component(.weekday, from: today)
            let offset = (weekday - Limits.weekStartWeekday + Limits.daysPerWeek) % Limits.daysPerWeek
            start = calendar.stepDays(-offset, from: today)
            end = calendar.stepDays(Limits.daysPerWeek, from: start)
        case .month:
            let month = calendar.dateInterval(of: .month, for: today)
            start = month?.start ?? today
            end = month?.end ?? calendar.nextDay(after: today)
        }
        return DateInterval(start: start, end: end)
    }

    package func build(_ range: ReportRange, now: Date, events: [HistoryEvent], prefs: Prefs) -> Report {
        let span = interval(range, containing: now)
        let inside = events.filter { span.start <= $0.date && $0.date < span.end }
        let slots = range == .day ? hourSlots(span) : daySlots(span)
        let days = daySlots(span).filter { $0.start <= now }
        let habits = HabitID.allCases.map { id in
            habitReport(id, goal: id.rules(prefs, calendar: calendar).dailyGoal, events: inside, slots: slots, days: days)
        }
        return Report(range: range, interval: span, habits: habits)
    }

    private func habitReport(_ id: HabitID, goal: Double, events: [HistoryEvent], slots: [DateInterval], days: [DateInterval]) -> HabitReport {
        let done = events.filter { $0.habit == id && $0.kind == .done }
        let buckets = slots.map { ReportBucket(start: $0.start, end: $0.end, total: sum(done, in: $0)) }
        let dayTotals = days.map { (start: $0.start, total: sum(done, in: $0)) }
        let total = buckets.reduce(0) { $0 + $1.total }
        let average = dayTotals.reduce(0) { $0 + $1.total } / Double(max(1, days.count))
        var best: (start: Date, total: Double)?
        for day in dayTotals where day.total > (best?.total ?? 0) {
            best = day
        }
        return HabitReport(
            habit: id,
            goal: goal,
            buckets: buckets,
            total: total,
            averagePerDay: average,
            percentOfGoal: goal > 0 ? min(Limits.fullPercent, Int((average / goal * Double(Limits.fullPercent)).rounded())) : 0,
            daysMet: goal > 0 ? dayTotals.filter { $0.total >= goal }.count : 0,
            bestDay: best?.start,
            snoozes: events.filter { $0.habit == id && $0.kind == .snooze }.count
        )
    }

    private func sum(_ events: [HistoryEvent], in slot: DateInterval) -> Double {
        events.reduce(0) { slot.start <= $1.date && $1.date < slot.end ? $0 + $1.amount : $0 }
    }

    private func daySlots(_ span: DateInterval) -> [DateInterval] {
        var slots: [DateInterval] = []
        var start = span.start
        while start < span.end {
            let end = min(calendar.nextDay(after: start), span.end)
            guard end > start else { break }
            slots.append(DateInterval(start: start, end: end))
            start = end
        }
        return slots
    }

    private func hourSlots(_ span: DateInterval) -> [DateInterval] {
        let starts = stride(from: 0, to: Limits.hoursPerDay, by: Limits.reportDayBucketHours).map { hour in
            hour == 0 ? span.start : max(span.start, calendar.date(bySettingHour: hour, minute: 0, second: 0, of: span.start) ?? span.start)
        }
        return starts.indices.map { i in
            DateInterval(start: starts[i], end: i + 1 < starts.count ? starts[i + 1] : span.end)
        }
    }
}
