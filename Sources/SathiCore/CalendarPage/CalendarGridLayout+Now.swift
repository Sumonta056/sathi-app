import Foundation

extension CalendarGridLayout {
    package func nowY(_ now: Date, minute: Int, day: DayKey) -> Double {
        let drawn = (days[day] ?? []).filter { !$0.isTodo && $0.span.start <= now }.map { Self.y(of: now, in: $0) }
        return ([y(atMinute: minute)] + drawn).max() ?? 0
    }

    private static func y(of now: Date, in laid: CalendarLaidBlock) -> Double {
        guard now < laid.span.end, laid.span.duration > 0 else { return laid.bottom }
        let share = now.timeIntervalSince(laid.span.start) / laid.span.duration
        return laid.top + (laid.bottom - laid.top) * share
    }
}
