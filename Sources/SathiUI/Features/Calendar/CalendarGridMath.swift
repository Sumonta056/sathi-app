import SathiCore
import SwiftUI

struct CalendarGridMath {
    let rows: [Date]
    let interval: DateInterval
    let hourHeight: CGFloat

    init(day: DayKey, calendar: Calendar, hourHeight: CGFloat) {
        rows = CalendarPageDay.hourStarts(of: day, calendar: calendar)
        interval = CalendarPageDay.interval(of: day, calendar: calendar)
        self.hourHeight = hourHeight
    }

    var totalHeight: CGFloat { hourHeight * CGFloat(rows.count) }

    var minimumMinutes: Double {
        Self.minimumMinutes(hourHeight: hourHeight)
    }

    static func minimumMinutes(rowMinutes: Int) -> Double {
        minimumMinutes(hourHeight: UIMetrics.calendarHourHeight(rowMinutes: rowMinutes))
    }

    static func minimumMinutes(hourHeight: CGFloat) -> Double {
        Double(UIMetrics.calendarBlockMinTextHeight / hourHeight) * Timing.hour / Timing.minute
    }

    func placed(_ data: CalendarPageData, day: DayKey, narrow: Set<CalendarLaneShape> = []) -> [CalendarPlacedBlock] {
        guard data.placedMinimumMinutes == minimumMinutes, data.placedNarrow == narrow, let cached = data.placed[day] else {
            return place(data.blocks, narrow: narrow)
        }
        return cached
    }

    func place(_ blocks: [CalendarBlock], narrow: Set<CalendarLaneShape> = []) -> [CalendarPlacedBlock] {
        CalendarBlockLayout.place(blocks, within: interval, minimumMinutes: minimumMinutes, narrow: narrow)
    }

    func y(for date: Date) -> CGFloat {
        guard date > interval.start else { return 0 }
        guard date < interval.end, let row = rows.lastIndex(where: { $0 <= date }) else { return totalHeight }
        let length = rowEnd(row).timeIntervalSince(rows[row])
        let part = length > 0 ? date.timeIntervalSince(rows[row]) / length : 0
        return (CGFloat(row) + CGFloat(min(1, part))) * hourHeight
    }

    func height(_ span: DateInterval) -> CGFloat {
        y(for: span.end) - y(for: span.start)
    }

    func slotStart(y: CGFloat) -> Date {
        let clamped = min(max(0, y), totalHeight - 1)
        let row = min(rows.count - 1, Int(clamped / hourHeight))
        let part = Double((clamped - CGFloat(row) * hourHeight) / hourHeight)
        let offset = part * rowEnd(row).timeIntervalSince(rows[row])
        let slot = TimeInterval(Limits.calendarSlotMinutes) * Timing.minute
        return rows[row].addingTimeInterval((offset / slot).rounded(.down) * slot)
    }

    func holds(_ date: Date) -> Bool {
        interval.contains(date) && date < interval.end
    }

    private func rowEnd(_ row: Int) -> Date {
        row + 1 < rows.count ? rows[row + 1] : interval.end
    }
}
