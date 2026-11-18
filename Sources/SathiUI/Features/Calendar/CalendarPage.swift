import SathiCore
import SwiftUI

struct CalendarPage: View {
    let day: DayKey?
    @State private var picked: CalendarPageRange?
    @State private var memo = RangeMemo<CalendarPageRequest, CalendarPageData>()
    @State var focus: CalendarPageFocus
    @State var selected: Set<ActivityID> = []
    @State var mergeError: String?
    @State var narrowStats: Bool
    @State var narrowLanes = CalendarLaneMemory.remembered
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
        let request = CalendarPageRequest(range: range, narrow: CalendarLaneMemory.narrow(narrowLanes, for: range.kind))
        let data = e.calendarAccess == .allowed ? memo.value(request, end: range.interval.end, engine: e) {
            $0.calendarPage(
                $1.range, minimumMinutes: CalendarGridMath.minimumMinutes(rowMinutes: $0.data.prefs.calendarPage.rowMinutes), narrow: $1.narrow
            )
        } : nil
        let sidePanelShown = layout.isNarrow ? narrowStats : e.data.prefs.calendarPage.sidePanelShown(for: range.kind)
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            CalendarPageHeader(
                range: binding(range), now: e.now, calendar: e.rangeCalendar, stats: data?.stats, sidePanelShown: sidePanelShown,
                toggleSidePanel: { toggleSidePanel(range.kind) }, rowMinutes: rowMinutes
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

    private func toggleSidePanel(_ kind: ReportRange) {
        if layout.isNarrow { return narrowStats.toggle() }
        e.setCalendarSidePanelShown(!e.data.prefs.calendarPage.sidePanelShown(for: kind), for: kind)
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
                    if range.kind == .day { strip(data) } else if let mergeError { errorLine(mergeError) }
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
                rowMinutes: e.data.prefs.calendarPage.rowMinutes, narrow: CalendarLaneMemory.narrow(narrowLanes, for: range.kind),
                measured: { width in
                    guard let next = CalendarLaneMemory.next(narrowLanes, kind: range.kind, columnWidth: width) else { return }
                    CalendarLaneMemory.remembered = next
                    narrowLanes = next
                }
            )
        }
    }

    private func strip(_ data: CalendarPageData) -> some View {
        CalendarMergeStrip(
            rows: CalendarMergePick.rows(data.blocks), calendar: e.rangeCalendar, canUndo: e.mergeUndo != nil,
            actions: .merging(e), selected: $selected, error: $mergeError
        )
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
