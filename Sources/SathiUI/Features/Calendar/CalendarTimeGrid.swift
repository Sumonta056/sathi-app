import SathiCore
import SwiftUI

struct CalendarTimeGrid: View {
    let range: CalendarPageRange
    let data: CalendarPageData
    let now: Date
    let calendar: Calendar
    let categories: [ActivityCategory]
    var actions = CalendarGridActions()
    var selected: Set<ActivityID> = []
    var popover: Binding<CalendarPopoverTarget?> = .constant(nil)
    var rowMinutes = Limits.calendarDefaultRowMinutes
    var narrow: Set<CalendarLaneShape> = []
    var measured: (CGFloat) -> Void = { _ in }
    @State private var box = CalendarHoverBox()

    static let hourLabels = (0 ..< Limits.calendarGridHours).map {
        Copywriter.calendarHourLabel(hour: (Limits.calendarPageDayStartHour + $0) % Limits.calendarGridHours)
    }

    var initialRow: Int { range.initialScrollRow(now: now) }

    private var hourHeight: CGFloat { UIMetrics.calendarHourHeight(rowMinutes: rowMinutes) }

    private var hover: CalendarHoverHost { box.host }

    private var subLines: Int { Limits.minutesPerHour / max(1, rowMinutes) - 1 }

    var body: some View {
        let today = CalendarPageDay.key(holding: now, calendar: calendar)
        let columns = range.days.map { CalendarGridMath(day: $0, calendar: calendar, hourHeight: hourHeight) }
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
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    labels
                    ForEach(Array(zip(range.days, columns)), id: \.0) { day, math in
                        CalendarDayColumn(
                            day: day, placed: math.placed(data, day: day, narrow: narrow), texts: data.texts,
                            math: math, now: day == today ? now : nil, categories: categories, calendar: calendar,
                            actions: actions, selected: selected, popover: popover, showsAwayPill: range.kind == .day,
                            hover: { [hover] in hover.block($0, inside: $1) }, weekSides: range.kind == .week
                        )
                        .overlay(alignment: .leading) { Night.divider.frame(width: UIMetrics.calendarLine) }
                    }
                }
                .background(alignment: .top) { hourLines }
                .background { CalendarColumnWidth(days: range.days.count, measured: measured) }
                .coordinateSpace(name: CalendarHoverHost.space)
                .overlay(alignment: .topLeading) {
                    CalendarHoverLayer(host: hover, grid: actions, height: columns.first?.totalHeight ?? 0)
                }
            }
            .onAppear { proxy.scrollTo(initialRow, anchor: .top) }
            .onChange(of: range) {
                hover.close()
                proxy.scrollTo($0.initialScrollRow(now: now), anchor: .top)
            }
            .onChange(of: rowMinutes) { _ in proxy.scrollTo(initialRow, anchor: .top) }
            .onChange(of: data) { hover.keep(ids: $0.shownIDs) }
        }
    }

    private var labels: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.hourLabels.enumerated()), id: \.offset) { row, label in
                Text(verbatim: label)
                    .font(Typography.tracker(UIMetrics.calendarHourFont, .semibold))
                    .foregroundStyle(Night.faint)
                    .padding(.top, UIMetrics.calendarColumnInset)
                    .frame(width: UIMetrics.calendarHourLabelWidth, height: hourHeight, alignment: .top)
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
                .frame(height: hourHeight)
                .overlay(alignment: .top) {
                    ForEach(0 ..< subLines, id: \.self) { index in
                        Night.divider.opacity(UIMetrics.calendarSubLineOpacity)
                            .frame(height: UIMetrics.calendarLine)
                            .offset(y: hourHeight * CGFloat(index + 1) / CGFloat(subLines + 1))
                            .accessibilityIdentifier("calendar.subline")
                    }
                }
            }
        }
    }
}
