import SathiCore
import SwiftUI

struct CalendarGridMark: Equatable {
    let y: CGFloat
    let isHour: Bool
}

struct CalendarRailLabel: Equatable {
    let row: Int
    let text: String
}

enum CalendarSplitClock {
    static func minute(_ date: Date, day: DayKey, calendar: Calendar) -> Int {
        let interval = CalendarPageDay.interval(of: day, calendar: calendar)
        if date <= interval.start { return 0 }
        if date >= interval.end { return Limits.minutesPerDay }
        let g = Calendar.gregorian(in: calendar.timeZone)
        let c = g.dateComponents([.hour, .minute], from: date)
        let hour = c.hour ?? 0
        let wall = (hour - Limits.calendarPageDayStartHour) * Limits.minutesPerHour + (c.minute ?? 0)
        let m = hour < Limits.calendarPageDayStartHour ? wall + Limits.minutesPerDay : wall
        return min(max(m, 0), Limits.minutesPerDay)
    }

    static func date(minute: Int, day: DayKey, calendar: Calendar) -> Date {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let wall = Limits.calendarPageDayStartHour * Limits.minutesPerHour + minute
        let base = g.date(byAdding: .day, value: wall / Limits.minutesPerDay, to: day.start(in: g)) ?? day.start(in: g)
        let rest = wall % Limits.minutesPerDay
        return g.date(
            bySettingHour: rest / Limits.minutesPerHour, minute: rest % Limits.minutesPerHour, second: 0, of: base
        ) ?? base
    }

    static func slotStart(y: CGFloat, grid: CalendarGridLayout, day: DayKey, calendar: Calendar) -> Date {
        let row = grid.rows.last { Double(y) >= $0.top } ?? grid.rows.first
        guard let row else { return date(minute: 0, day: day, calendar: calendar) }
        let span = row.endMinute - row.startMinute
        let into = Double(y) - row.top
        let offset = row.isFold ? into / max(row.height, 1) * Double(span) : into / max(grid.pointsPerMinute, .ulpOfOne)
        let minute = row.startMinute + min(max(0, Int(offset)), max(0, span - 1))
        let slot = Limits.calendarSlotMinutes
        return date(minute: minute / slot * slot, day: day, calendar: calendar)
    }

    static func initialRow(_ grid: CalendarGridLayout, range: CalendarPageRange, now: Date, calendar: Calendar) -> Int {
        guard range.holds(now) else { return 0 }
        let day = CalendarPageDay.key(holding: now, calendar: calendar)
        let m = minute(now, day: day, calendar: calendar)
        return grid.rows.firstIndex { $0.holds(m) } ?? 0
    }

    static func marks(_ grid: CalendarGridLayout) -> [CalendarGridMark] {
        let quarter = UIMetrics.calendarQuarterMinutes
        return grid.rows.filter { !$0.isFold }.flatMap { row in
            stride(from: row.startMinute, to: row.endMinute, by: quarter).map { m in
                CalendarGridMark(
                    y: CGFloat(row.top + Double(m - row.startMinute) * grid.pointsPerMinute),
                    isHour: m % Limits.minutesPerHour == 0
                )
            }
        }
    }

    static func labels(_ grid: CalendarGridLayout) -> [CalendarRailLabel] {
        grid.rows.enumerated().compactMap { index, row in
            guard !row.isFold, row.startMinute % Limits.minutesPerHour == 0 else { return nil }
            let hour = (Limits.calendarPageDayStartHour + row.startMinute / Limits.minutesPerHour) % Limits.hoursPerDay
            return CalendarRailLabel(row: index, text: Copywriter.calendarHourLabel(hour: hour))
        }
    }
}
