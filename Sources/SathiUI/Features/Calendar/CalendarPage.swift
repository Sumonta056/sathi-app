import SathiCore
import SwiftUI

struct CalendarPage: View {
    let day: DayKey?
    @State private var picked: CalendarPageRange?
    @State private var memo = RangeMemo<CalendarPageRequest, CalendarPageData>()
    @State var focus: CalendarPageFocus
    @State var failure: String?
    @State var narrowStats: Bool
    @State var narrowWeek = CalendarNarrowMemory.week
    @Environment(\.mainLayout) var layout
    @EnvironmentObject var e: Engine

    init(day: DayKey? = nil, range: CalendarPageRange? = nil, editing: CalendarActivityEdit? = nil, narrowStats: Bool = false) {
        self.day = day
        _narrowStats = State(initialValue: narrowStats)
        _picked = State(initialValue: range)
        _focus = State(initialValue: CalendarPageFocus(editing: editing))
    }

    var body: some View {
        let range = shown
        let request = CalendarPageRequest(range: range, narrow: range.kind == .week && narrowWeek)
        let data = e.calendarAccess == .allowed ? memo.value(request, end: range.interval.end, engine: e) {
            $0.calendarPage($1.range, metrics: CalendarSplitMetrics.metrics(
                kind: $1.range.kind, rowMinutes: $0.data.prefs.calendarPage.rowMinutes, narrow: $1.narrow
            ))
        } : nil
        let sidePanelShown = layout.isNarrow ? narrowStats : e.data.prefs.calendarPage.sidePanelShown(for: range.kind)
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            CalendarPageHeader(
                range: binding(range), now: e.now, calendar: e.rangeCalendar, stats: data?.stats, sidePanelShown: sidePanelShown,
                toggleSidePanel: { toggleSidePanel(range.kind) }, rowMinutes: rowMinutes, today: e.calendarPageToday,
                weekDays: e.data.prefs.calendarPage.weekDays, pickDays: { picked = Self.pickDays($0, engine: e) }
            )
            content(range, data)
        }
        .padding(UIMetrics.mainContentPadding)
        .overlay { drawer }
        .onAppear {
            e.refreshCalendarAccess()
            e.calendarPageOpened()
        }
        .onDisappear { e.calendarPageClosed() }
        .onChange(of: day) { _ in picked = nil }
        .modifier(CalendarRangeReset(range: range, focus: $focus, failure: $failure))
    }

    private func toggleSidePanel(_ kind: ReportRange) {
        if layout.isNarrow { return narrowStats.toggle() }
        e.setCalendarSidePanelShown(!e.data.prefs.calendarPage.sidePanelShown(for: kind), for: kind)
    }

    private var shown: CalendarPageRange {
        if let picked { return picked }
        let calendar = e.rangeCalendar
        let weekDays = e.data.prefs.calendarPage.weekDays
        guard let day else { return .containing(e.now, kind: .day, calendar: calendar, weekDays: weekDays) }
        return .containing(day: day, kind: .day, calendar: calendar, weekDays: weekDays)
    }

    @ViewBuilder private func content(_ range: CalendarPageRange, _ data: CalendarPageData?) -> some View {
        if let data {
            HStack(alignment: .top, spacing: UIMetrics.calendarSideGap) {
                VStack(alignment: .leading, spacing: UIMetrics.calendarSideGap) {
                    if let failure { errorLine(failure) }
                    grid(range, data)
                }
                side(data, kind: range.kind)
            }
            .overlay(alignment: .topTrailing) { floating(data, kind: range.kind) }
        } else {
            CalendarAccessGate()
        }
    }

    @ViewBuilder private func grid(_ range: CalendarPageRange, _ data: CalendarPageData) -> some View {
        if range.kind == .month {
            ScrollView(.vertical, showsIndicators: false) {
                CalendarMonthGrid(cells: data.monthCells, range: binding(range), calendar: e.rangeCalendar, categories: e.activityCategories)
            }
        } else {
            CalendarSplitGrid(
                range: range, data: data, now: e.now, calendar: e.rangeCalendar, categories: e.activityCategories,
                actions: gridActions(), popover: $focus.popover, narrow: range.kind == .week && narrowWeek,
                calendarNames: range.kind == .day ? data.calendarNames : [:]
            ) { measure in
                let next = CalendarSplitMetrics.narrow(measure, current: narrowWeek)
                guard next != narrowWeek else { return }
                CalendarNarrowMemory.week = next
                narrowWeek = next
            }
        }
    }

    static func pickDays(_ n: Int, engine: Engine) -> CalendarPageRange {
        engine.setCalendarWeekDays(n)
        return engine.calendarPageToday(.week)
    }

    private func errorLine(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Typography.hint)
            .foregroundStyle(Night.tracker)
            .accessibilityIdentifier("calendar.page.error")
    }

    private var rowMinutes: Binding<Int> {
        Binding(get: { e.data.prefs.calendarPage.rowMinutes }, set: { e.setCalendarRowMinutes($0) })
    }

    private func binding(_ range: CalendarPageRange) -> Binding<CalendarPageRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
