import AppKit
import SathiCore
import SwiftUI

struct ActivityReportsView: View {
    @EnvironmentObject var e: Engine
    @Binding var range: ActivityRange
    @Binding var day: DayKey?
    @State private var month: MonthKey?

    var body: some View {
        let cal = calendar
        switch range {
        case .day:
            ActivityDayView(day: e.activityDay(shownDay), categories: e.activityCategories, calendar: cal, actions: dayActions)
        case .month:
            ActivityMonthView(
                month: shownMonth, days: e.activityDays(in: shownMonth), categories: e.activityCategories,
                calendar: cal, actions: monthActions
            )
        }
    }

    private var calendar: Calendar {
        var c = Calendar.current
        c.timeZone = e.timeZone
        return c
    }

    private var shownDay: DayKey { day ?? DayKey(e.now, calendar: calendar) }
    private var shownMonth: MonthKey { month ?? MonthKey(shownDay.start(in: calendar), calendar: calendar) }

    private var dayActions: ActivityDayActions {
        let engine = e
        var a = ActivityDayActions()
        a.select = { day = $0 }
        a.marks = { engine.daysWithActivities(in: $0) }
        a.edit = { engine.editActivity($0, $1) }
        a.add = { engine.addPastActivity($0) }
        a.delete = { engine.deleteActivity($0) }
        a.saveToCalendar = { engine.saveActivityToCalendar($0) }
        return a
    }

    private var monthActions: ActivityMonthActions {
        let engine = e
        let shown = shownMonth
        var a = ActivityMonthActions()
        a.selectMonth = { month = $0 }
        a.openDay = {
            day = $0
            range = .day
        }
        a.exportMonth = { ActivityMonthExport.run(engine, month: shown) }
        return a
    }
}

@MainActor
enum ActivityMonthExport {
    static func run(
        _ engine: Engine,
        month: MonthKey,
        folder: URL? = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first,
        reveal: ([URL]) -> Void = { NSWorkspace.shared.activateFileViewerSelecting($0) }
    ) {
        guard let folder else { return NSSound.beep() }
        let urls = engine.exportActivityMonth(month, to: folder)
        guard !urls.isEmpty else { return NSSound.beep() }
        reveal(urls)
    }
}
