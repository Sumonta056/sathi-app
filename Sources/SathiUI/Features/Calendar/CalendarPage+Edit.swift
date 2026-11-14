import SathiCore
import SwiftUI

extension CalendarPage {
    static func open(_ block: CalendarBlock, engine: Engine) -> CalendarOpen {
        switch block.source {
        case let .event(info):
            return .event(engine.calendarPageForm(for: info))
        case let .activity(a, _):
            return .activity(CalendarActivityEdit(day: DayKey(a.start, calendar: engine.rangeCalendar), target: .activity(a.id)))
        }
    }

    static func newEvent(at slot: Date, engine: Engine) -> CalendarEventForm {
        engine.calendarPageNewEvent(at: slot)
    }

    var gridActions: CalendarGridActions {
        let engine = e
        var a = CalendarGridActions()
        a.slot = { day, slot, y in
            editing = nil
            popover = CalendarPopoverTarget(day: day, y: y, form: Self.newEvent(at: slot, engine: engine))
        }
        a.block = { day, block, y in
            switch Self.open(block, engine: engine) {
            case let .event(form):
                editing = nil
                popover = CalendarPopoverTarget(day: day, y: y, form: form)
            case let .activity(edit):
                popover = nil
                editing = edit
            }
        }
        return a
    }

    @ViewBuilder func side(_ data: CalendarPageData, kind: ReportRange) -> some View {
        if let editing, case let day = e.activityDay(editing.day), ActivityEditPanel.shows(editing.target, in: day) {
            ActivityEditPanel(
                day: day, target: editing.target, categories: e.activityCategories, calendar: e.rangeCalendar,
                calendars: e.calendarChoices(), calendarNames: e.activityCalendarTitles, actions: .engine(e), editing: editTarget
            )
            .frame(width: UIMetrics.activitiesEditWidth)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                CalendarStatsPanel(stats: data.stats, kind: kind, categories: e.activityCategories)
            }
            .frame(width: UIMetrics.calendarSideWidth)
        }
    }

    private var editTarget: Binding<ActivityEditTarget?> {
        Binding(
            get: { editing?.target },
            set: { target in
                guard let target, let day = editing?.day else { return editing = nil }
                editing = CalendarActivityEdit(day: day, target: target)
            }
        )
    }
}
