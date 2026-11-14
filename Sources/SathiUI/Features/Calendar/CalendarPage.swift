import SathiCore
import SwiftUI

struct CalendarPage: View {
    @EnvironmentObject var e: Engine
    let day: DayKey?
    @State private var picked: CalendarPageRange?

    init(day: DayKey? = nil, range: CalendarPageRange? = nil) {
        self.day = day
        _picked = State(initialValue: range)
    }

    var body: some View {
        let range = shown
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            CalendarPageHeader(range: Binding(get: { range }, set: { picked = $0 }), now: e.now, calendar: e.rangeCalendar)
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
        return .containing(day.start(in: calendar), kind: .day, calendar: calendar)
    }

    @ViewBuilder private func content(_ range: CalendarPageRange) -> some View {
        if e.calendarAccess == .allowed {
            Spacer(minLength: 0)
        } else {
            CalendarAccessGate()
        }
    }
}
