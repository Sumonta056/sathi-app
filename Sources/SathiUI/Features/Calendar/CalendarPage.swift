import SathiCore
import SwiftUI

struct CalendarPage: View {
    let day: DayKey?
    @State private var picked: CalendarPageRange?
    @State private var memo = RangeMemo<CalendarPageRange, CalendarPageData>()
    @State var focus: CalendarPageFocus
    @State var selected: Set<ActivityID> = []
    @State var mergeError: String?
    @State var narrowStats: Bool
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
        let data = e.calendarAccess == .allowed ? memo.value(range, end: range.interval.end, engine: e) { $0.calendarPage($1) } : nil
        let sidePanelShown = layout.isNarrow ? narrowStats : e.data.prefs.calendarPage.sidePanelShown
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            CalendarPageHeader(
                range: binding(range), now: e.now, calendar: e.rangeCalendar, stats: data?.stats, sidePanelShown: sidePanelShown,
                toggleSidePanel: toggleSidePanel, rowMinutes: rowMinutes
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
        .modifier(CalendarRangeReset(range: range, focus: $focus, selected: $selected, error: $mergeError) { e.clearMergeUndo() })
    }

    private func toggleSidePanel() {
        if layout.isNarrow { return narrowStats.toggle() }
        e.setCalendarSidePanelShown(!e.data.prefs.calendarPage.sidePanelShown)
    }

    private var shown: CalendarPageRange {
        if let picked { return picked }
        let calendar = e.rangeCalendar
        guard let day else { return .containing(e.now, kind: .week, calendar: calendar) }
        return .containing(day: day, kind: .day, calendar: calendar)
    }

    @ViewBuilder private func content(_ range: CalendarPageRange, _ data: CalendarPageData?) -> some View {
        if let data {
            HStack(alignment: .top, spacing: UIMetrics.calendarSideGap) {
                VStack(alignment: .leading, spacing: UIMetrics.calendarSideGap) {
                    if range.kind == .day { strip(data) }
                    grid(range, data)
                }
                side(data, kind: range.kind)
            }
            .overlay(alignment: .topTrailing) { floating(data, kind: range.kind) }
            .modifier(CalendarSelectionPrune(blocks: data.blocks, selected: $selected, error: $mergeError))
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
            CalendarTimeGrid(
                range: range, data: data, now: e.now, calendar: e.rangeCalendar, categories: e.activityCategories,
                actions: gridActions(kind: range.kind), selected: range.kind == .day ? selected : [], popover: $focus.popover,
                rowMinutes: e.data.prefs.calendarPage.rowMinutes
            )
        }
    }

    private func strip(_ data: CalendarPageData) -> some View {
        CalendarMergeStrip(
            rows: CalendarMergePick.rows(data.blocks), calendar: e.rangeCalendar, canUndo: e.mergeUndo != nil,
            actions: .merging(e), selected: $selected, error: $mergeError
        )
    }

    private var rowMinutes: Binding<Int> {
        Binding(get: { e.data.prefs.calendarPage.rowMinutes }, set: { e.setCalendarRowMinutes($0) })
    }

    private func binding(_ range: CalendarPageRange) -> Binding<CalendarPageRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
