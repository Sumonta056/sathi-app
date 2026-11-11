import Foundation

extension Copywriter {
    package static let reportsAllBuddies = "All buddies"
    package static let reportsDayByDay = "Day by day"
    package static let reportsDayByDayLegend =
        "Solid cell = goal met · dim cell = some progress · dashed = still to come · click a buddy name to open its tab"
    package static let reportsTimeByCategory = "Time by category"
    package static let reportsOffCell = "Off"
    package static let reportsStreakLegend = "· green frame = streak day"
    package static let reportsPreviousMonth = "Previous month"
    package static let reportsNextMonth = "Next month"
    package static let reportsNoValue = "\u{2014}"

    package static func reportsTab(_ id: HabitID, met: Int, days: Int) -> String {
        id.buddy + " · " + reportsRingText(met, days: days)
    }

    package static func reportsRingText(_ met: Int, days: Int) -> String {
        "\(met)/\(days)"
    }

    package static func reportsGoalsOf(_ possible: Int) -> String {
        possible == 1 ? "of 1 goal" : "of \(possible) goals"
    }

    package static func reportsScoreLabel(_ kind: ReportRange, daysSoFar: Int, isCurrent: Bool) -> String {
        let word = kind == .day ? "DAY" : kind == .week ? "WEEK" : "MONTH"
        guard kind != .day else { return word + " SCORE" }
        let days = daysSoFar == 1 ? "1 DAY" : "\(daysSoFar) DAYS"
        return word + " SCORE · " + days + (isCurrent ? " SO FAR" : "")
    }

    package static func reportsHeadline(_ kind: ReportRange, scores: [BuddyScore]) -> String {
        let period = kind == .day ? "day" : kind == .week ? "week" : "month"
        let live = scores.filter { $0.counted > 0 }
        guard !live.isEmpty else { return "A quiet \(period) so far." }
        let met = live.reduce(0) { $0 + $1.met }
        let percent = met * Limits.fullPercent / live.reduce(0) { $0 + $1.counted }
        let lead = percent >= Limits.headlineGreatPercent ? "Great \(period)."
            : percent >= Limits.headlineGoodPercent ? "Good \(period)." : "Slow \(period)."
        if met == 0 { return lead + " Every goal is still open." }
        let ranked = live.enumerated().sorted { a, b in
            let left = a.element.met * b.element.counted
            let right = b.element.met * a.element.counted
            return left != right ? left > right : a.offset < b.offset
        }.map(\.element)
        guard let best = ranked.first, let weak = ranked.last,
              best.met * weak.counted > weak.met * best.counted else {
            return lead + (percent >= Limits.headlineGreatPercent ? " Every goal met." : " Every buddy is even.")
        }
        return "\(lead) \(best.habit.buddy) leads, \(weak.habit.buddy) needs a push."
    }

    package static func reportsScoreChange(_ diff: Int, kind: ReportRange, isCurrent: Bool, streak: Int) -> String {
        let before = isCurrent ? reportsSameSpan(kind) : rangeBefore(kind)
        let goals = abs(diff) == 1 ? "1 goal" : "\(abs(diff)) goals"
        let change = diff > 0 ? "+" + goals + " vs " + before
            : diff < 0 ? "\u{2212}" + goals + " vs " + before : "No change vs " + before
        return change + " · streak " + reportsDays(streak)
    }

    package static func reportsStreak(_ days: Int) -> String {
        "Streak " + reportsDays(days)
    }

    package static func reportsDayColumn(_ day: Date, kind: ReportRange, zone: TimeZone) -> String {
        rangeDate(day, kind == .month ? "d" : "EEE d", zone)
    }

    package static func reportsShortAmount(_ id: HabitID, _ amount: Double) -> String {
        let whole = amount.rounded() == amount
        let number = whole ? "\(Int(amount))" : String(format: "%.1f", amount)
        if id == .water { return number }
        if amount >= Double(Limits.minutesPerHour) { return Fmt.short(amount * Timing.minute) }
        return number + "m"
    }

    package static func reportsCategorySummary(_ table: CategoryTable, kind: ReportRange) -> String {
        let previous = table.rows.compactMap { row -> Double? in
            switch row.change {
            case let .up(d): row.seconds - d
            case let .down(d): row.seconds + d
            case .same: row.seconds
            case .none: nil
            }
        }
        guard !previous.isEmpty else { return table.rows.count == 1 ? "logged · 1 category" : "logged · \(table.rows.count) categories" }
        let change = RangeChange(current: table.totalSeconds, previous: previous.reduce(0, +), hasData: true)
        return rangeChange(change, kind: kind) { categoryTableHours($0) }
    }

    static func reportsDays(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private static func reportsSameSpan(_ kind: ReportRange) -> String {
        switch kind {
        case .day: "the same time yesterday"
        case .week: "the same days last week"
        case .month: "the same days last month"
        }
    }
}
