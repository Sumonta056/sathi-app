import SathiCore
import SwiftUI

struct CalendarAllDayRow: View {
    let days: [DayKey]
    let blocks: [CalendarBlock]
    let categories: [ActivityCategory]
    let calendar: Calendar

    static func blocks(_ blocks: [CalendarBlock], on day: DayKey, calendar: Calendar) -> [CalendarBlock] {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let start = day.start(in: g)
        let dated = DateInterval(start: start, end: g.date(byAdding: .day, value: 1, to: start) ?? start)
        return blocks.filter { b in
            let i = b.interval
            if i.duration == 0 { return dated.start <= i.start && i.start < dated.end }
            return i.start < dated.end && i.end > dated.start
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(verbatim: Copywriter.calendarAllDay)
                .font(Typography.tracker(UIMetrics.calendarHourFont, .semibold))
                .foregroundStyle(Night.faint)
                .frame(width: UIMetrics.calendarHourLabelWidth, alignment: .center)
            ForEach(days, id: \.self) { day in
                VStack(spacing: UIMetrics.calendarChipGap) {
                    ForEach(Self.blocks(blocks, on: day, calendar: calendar)) { CalendarChip(block: $0, categories: categories) }
                }
                .padding(.horizontal, UIMetrics.calendarColumnInset)
                .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarAllDayHeight, alignment: .top)
            }
        }
        .padding(.vertical, UIMetrics.calendarChipGap)
    }
}
