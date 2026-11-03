import Foundation

extension ReportScreenBuilder {
    func streakMonth(_ habit: HabitReport, streak: Int, now: Date) -> StreakMonth {
        let first = habit.buckets.first?.start ?? calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: first)
        let cells = habit.buckets.enumerated().map { index, bucket in
            let isFuture = bucket.start > now
            let shade = isFuture ? 0 : Self.level(bucket.total, goal: habit.goal)
            let isOff = bucket.isOff && shade < Self.metLevel
            return StreakCell(
                day: index + 1,
                level: isOff ? 0 : shade,
                isToday: calendar.isDate(bucket.start, inSameDayAs: now),
                isFuture: isFuture,
                isOff: isOff
            )
        }
        return StreakMonth(
            title: monthName.string(from: now) + " streak",
            streakText: Self.days(streak),
            leadingBlanks: (weekday - Limits.weekStartWeekday + Limits.daysPerWeek) % Limits.daysPerWeek,
            cells: cells
        )
    }

    static func level(_ total: Double, goal: Double) -> Int {
        let ratio = goal > 0 ? total / goal : 0
        if ratio <= 0 { return 0 }
        if ratio < Limits.streakLevelMid { return 1 }
        if ratio < 1 { return 2 }
        return metLevel
    }

    static let metLevel = 3
}
