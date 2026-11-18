import SathiCore
import SwiftUI

struct CalendarSplitGrid: View {
    let range: CalendarPageRange
    let data: CalendarPageData
    let now: Date
    let calendar: Calendar
    let categories: [ActivityCategory]
    var actions = CalendarGridActions()
    var popover: Binding<CalendarPopoverTarget?> = .constant(nil)
    var narrow = false
    var calendarNames: [String: String] = [:]
    var measured: (CGFloat) -> Void = { _ in }
    @State private var box = CalendarHoverBox()

    private var hover: CalendarHoverHost { box.host }
    private var grid: CalendarGridLayout { data.grid ?? CalendarGridLayout(rows: [], days: [:], height: 0, pointsPerMinute: 0) }

    static func ringRadius(_ laid: CalendarLaidBlock, kind: ReportRange) -> CGFloat {
        if laid.isTodo { return UIMetrics.calendarTodoPillHeight / 2 }
        return kind == .day ? UIMetrics.calendarDayCardRadius : UIMetrics.calendarWeekBlockRadius
    }

    static func column(total: CGFloat, days: Int) -> CGFloat {
        max(0, total - UIMetrics.calendarHourLabelWidth) / CGFloat(max(1, days))
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarGridRadius, style: .continuous)
        GeometryReader { geo in
            let column = Self.column(total: geo.size.width, days: range.days.count)
            VStack(spacing: 0) {
                header(column)
                if !data.allDay.isEmpty {
                    CalendarAllDayRow(days: range.days, blocks: data.allDay, categories: categories, calendar: calendar)
                    line
                }
                scroller(column)
            }
            .onAppear { measured(column) }
            .onChange(of: column) { measured($0) }
        }
        .background(shape.fill(Night.card))
        .clipShape(shape)
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    @ViewBuilder private func header(_ column: CGFloat) -> some View {
        if range.kind == .week {
            CalendarWeekHeaders(days: range.days, today: today, calendar: calendar, column: column)
            line
        } else if let day = range.days.first {
            HStack(spacing: 0) {
                Color.clear.frame(width: UIMetrics.calendarHourLabelWidth)
                CalendarDayHeader(
                    blocks: grid.days[day] ?? [],
                    actualWidth: CalendarSplitGeometry.halves(column: column, kind: .day).actualWidth
                )
                .frame(width: column, alignment: .leading)
            }
            line
        }
    }

    private var today: DayKey { CalendarPageDay.key(holding: now, calendar: calendar) }

    private var line: some View {
        Night.divider.frame(height: UIMetrics.calendarLine)
    }

    private func scroller(_ column: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    CalendarSplitRail(grid: grid)
                    columns(column)
                        .background(alignment: .topLeading) { CalendarSplitLines(grid: grid, showsFoldText: range.kind == .week) }
                }
                .frame(height: CGFloat(grid.height), alignment: .top)
                .overlay(alignment: .topLeading) {
                    CalendarHoverLayer(host: hover, grid: actions, height: CGFloat(grid.height))
                }
            }
            .onAppear { proxy.scrollTo(initialRow, anchor: .top) }
            .onChange(of: range) {
                hover.close()
                proxy.scrollTo(CalendarSplitClock.initialRow(grid, range: $0, now: now, calendar: calendar), anchor: .top)
            }
            .onChange(of: data.grid) { next in hover.keep(ids: Set(next?.days.values.joined().flatMap { [$0] + $0.hidden }.map(\.id) ?? [])) }
        }
    }

    private var initialRow: Int {
        CalendarSplitClock.initialRow(grid, range: range, now: now, calendar: calendar)
    }

    private func columns(_ width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(range.days.enumerated()), id: \.element) { index, day in
                let blocks = grid.days[day] ?? []
                CalendarSplitColumn(
                    day: day, kind: range.kind, blocks: blocks, grid: grid, width: width, now: day == today ? now : nil,
                    calendar: calendar, categories: categories, narrow: narrow, calendarNames: calendarNames,
                    actions: actions, popover: popover
                ) { laid, rect, inside in
                    hover.block(target(laid, among: blocks, day: day, rect: rect, x: CGFloat(index) * width), inside: inside)
                }
                .overlay(alignment: .leading) { Night.divider.frame(width: UIMetrics.calendarLine) }
            }
        }
    }

    private func target(_ laid: CalendarLaidBlock, among: [CalendarLaidBlock], day: DayKey, rect: CGRect, x: CGFloat) -> CalendarHoverTarget {
        CalendarHoverTarget(
            day: day, laid: laid, among: among,
            rect: rect.offsetBy(dx: x + UIMetrics.calendarHourLabelWidth, dy: 0),
            radius: Self.ringRadius(laid, kind: range.kind),
            prefersLeft: range.kind == .week && CalendarHoverPlacement.prefersLeft(day: day, calendar: calendar)
        )
    }
}
