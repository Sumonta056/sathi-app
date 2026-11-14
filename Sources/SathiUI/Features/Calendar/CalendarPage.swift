import SathiCore
import SwiftUI

struct CalendarPage: View {
    @EnvironmentObject var e: Engine
    let day: DayKey?
    @State private var picked: CalendarPageRange?
    @State private var memo = RangeMemo<CalendarPageRange, CalendarPageData>()

    init(day: DayKey? = nil, range: CalendarPageRange? = nil) {
        self.day = day
        _picked = State(initialValue: range)
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
            if range.kind == .month {
                ScrollView(.vertical) {
                    CalendarMonthGrid(cells: data.monthCells, range: binding(range), calendar: e.rangeCalendar, categories: e.activityCategories)
                }
            } else {
                CalendarTimeGrid(range: range, data: data, now: e.now, calendar: e.rangeCalendar, categories: e.activityCategories)
            }
        } else {
            CalendarAccessGate()
        }
    }

    private func binding(_ range: CalendarPageRange) -> Binding<CalendarPageRange> {
        Binding(get: { range }, set: { picked = $0 })
    }
}
