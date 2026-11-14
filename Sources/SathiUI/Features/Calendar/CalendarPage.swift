import SathiCore
import SwiftUI

struct CalendarPage: View {
    let day: DayKey?
    @State private var picked: CalendarPageRange?
    @State private var memo = RangeMemo<CalendarPageRange, CalendarPageData>()
    @State var focus: CalendarPageFocus
    @State var selected: Set<ActivityID> = []
    @State var mergeError: String?
    @EnvironmentObject var e: Engine

    init(day: DayKey? = nil, range: CalendarPageRange? = nil, editing: CalendarActivityEdit? = nil) {
        self.day = day
        _picked = State(initialValue: range)
        _focus = State(initialValue: CalendarPageFocus(editing: editing))
    }

    var body: some View {
        let range = shown
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            CalendarPageHeader(range: binding(range), now: e.now, calendar: e.rangeCalendar)
            content(range)
        }
        .padding(UIMetrics.mainContentPadding)
        .onAppear {
            e.refreshCalendarAccess()
            e.calendarPageOpened()
        }
        .onDisappear { e.calendarPageClosed() }
        .onChange(of: day) { _ in picked = nil }
        .onChange(of: range) { _ in
            focus = CalendarPageFocus()
            selected = []
            mergeError = nil
            e.clearMergeUndo()
        }
    }

    private var shown: CalendarPageRange {
        if let picked { return picked }
        let calendar = e.rangeCalendar
        guard let day else { return .containing(e.now, kind: .day, calendar: calendar) }
        return .containing(day: day, kind: .day, calendar: calendar)
    }

    @ViewBuilder private func content(_ range: CalendarPageRange) -> some View {
        if e.calendarAccess == .allowed {
            let data = memo.value(range, end: range.interval.end, engine: e) { $0.calendarPage($1) }
            HStack(alignment: .top, spacing: UIMetrics.calendarSideGap) {
                VStack(alignment: .leading, spacing: UIMetrics.calendarSideGap) {
                    if range.kind != .day { CalendarStatsLine(stats: data.stats, kind: range.kind) } else { strip(data) }
                    grid(range, data)
                }
                side(data, kind: range.kind)
            }
            .onChange(of: data.blocks) { selected = CalendarMergePick.pruned(selected, in: CalendarMergePick.rows($0)) }
        } else {
            CalendarAccessGate()
        }
    }

    @ViewBuilder private func grid(_ range: CalendarPageRange, _ data: CalendarPageData) -> some View {
        if range.kind == .month {
            ScrollView(.vertical) {
                CalendarMonthGrid(cells: data.monthCells, range: binding(range), calendar: e.rangeCalendar, categories: e.activityCategories)
            }
        } else {
            CalendarTimeGrid(
                range: range, data: data, now: e.now, calendar: e.rangeCalendar, categories: e.activityCategories,
                actions: gridActions(kind: range.kind), selected: range.kind == .day ? selected : [], popover: $focus.popover
            )
        }
    }

    private func strip(_ data: CalendarPageData) -> some View {
        CalendarMergeStrip(
            rows: CalendarMergePick.rows(data.blocks), calendar: e.rangeCalendar, canUndo: e.mergeUndo != nil,
            actions: .merging(e), selected: $selected, error: $mergeError
        )
    }

    private func binding(_ range: CalendarPageRange) -> Binding<CalendarPageRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
