import SathiCore
import SwiftUI

struct CalendarTimeGrid: View {
    let range: CalendarPageRange
    let data: CalendarPageData
    let now: Date
    let calendar: Calendar
    let categories: [ActivityCategory]

    static let hourLabels = (0 ..< Limits.calendarGridHours).map {
        Copywriter.calendarHourLabel(hour: (Limits.calendarPageDayStartHour + $0) % Limits.calendarGridHours)
    }

    var initialRow: Int { range.initialScrollRow(now: now) }

    var body: some View {
        let today = CalendarPageDay.key(holding: now, calendar: calendar)
        let columns = range.days.map { CalendarGridMath(day: $0, calendar: calendar, hourHeight: UIMetrics.calendarHourHeight) }
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarGridRadius, style: .continuous)
        VStack(spacing: 0) {
            if range.kind == .week {
                CalendarDayHeaders(days: range.days, today: today, calendar: calendar)
                line
            }
            if !data.allDay.isEmpty {
                CalendarAllDayRow(days: range.days, blocks: data.allDay, categories: categories, calendar: calendar)
                line
            }
            scroller(columns, today: today)
        }
        .background(shape.fill(Night.card))
        .clipShape(shape)
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var line: some View {
        Night.divider.frame(height: UIMetrics.calendarLine)
    }

    private func scroller(_ columns: [CalendarGridMath], today: DayKey) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: 0) {
                    labels
                    ForEach(Array(zip(range.days, columns)), id: \.0) { day, math in
                        CalendarDayColumn(
                            placed: CalendarBlockLayout.place(data.blocks, within: math.interval), texts: data.texts,
                            math: math, now: day == today ? now : nil, categories: categories, calendar: calendar
                        )
                        .overlay(alignment: .leading) { Night.divider.frame(width: UIMetrics.calendarLine) }
                    }
                }
                .background(alignment: .top) { hourLines }
            }
            .onAppear { proxy.scrollTo(initialRow, anchor: .top) }
            .onChange(of: range) { proxy.scrollTo($0.initialScrollRow(now: now), anchor: .top) }
        }
    }

    private var labels: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.hourLabels.enumerated()), id: \.offset) { row, label in
                Text(verbatim: label)
                    .font(Typography.tracker(UIMetrics.calendarHourFont, .semibold))
                    .foregroundStyle(Night.faint)
                    .padding(.top, UIMetrics.calendarColumnInset)
                    .frame(width: UIMetrics.calendarHourLabelWidth, height: UIMetrics.calendarHourHeight, alignment: .top)
                    .id(row)
            }
        }
    }

    private var hourLines: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Limits.calendarGridHours, id: \.self) { _ in
                VStack(spacing: 0) {
                    line
                    Spacer(minLength: 0)
                }
                .frame(height: UIMetrics.calendarHourHeight)
            }
        }
    }
}
