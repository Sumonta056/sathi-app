import SathiCore
import SwiftUI

extension CalendarPage {
    static func open(_ block: CalendarBlock, engine: Engine) -> CalendarOpen? {
        switch block.source {
        case let .event(info):
            return .event(engine.calendarPageForm(for: info))
        case let .activity(a, running):
            guard !running else { return nil }
            return .activity(CalendarActivityEdit(day: DayKey(a.start, calendar: engine.rangeCalendar), target: .activity(a.id)))
        case .todo:
            return nil
        }
    }

    static func newEvent(at slot: Date, engine: Engine) -> CalendarEventForm {
        engine.calendarPageNewEvent(at: slot)
    }

    static func tap(_ block: CalendarBlock, day: DayKey, y: CGFloat, engine: Engine, focus: inout CalendarPageFocus) {
        switch open(block, engine: engine) {
        case let .event(form):
            focus = CalendarPageFocus(popover: CalendarPopoverTarget(day: day, y: y, form: form))
        case let .activity(edit):
            focus = CalendarPageFocus(editing: edit)
        case nil:
            break
        }
    }

    func gridActions(kind: ReportRange) -> CalendarGridActions {
        .page(kind: kind, engine: e, focus: $focus, selected: $selected, error: $mergeError)
    }

    @ViewBuilder func side(_ data: CalendarPageData, kind: ReportRange) -> some View {
        if !layout.drawerEdit, let shown = shownEdit {
            editPanel(shown).frame(width: UIMetrics.activitiesEditWidth)
        } else if !layout.isNarrow, e.data.prefs.calendarPage.sidePanelShown {
            stats(data, kind: kind).frame(width: UIMetrics.calendarSideWidth)
        }
    }

    @ViewBuilder func floating(_ data: CalendarPageData, kind: ReportRange) -> some View {
        if layout.isNarrow, narrowStats {
            CalendarFloatingPanel { stats(data, kind: kind) }
        }
    }

    @ViewBuilder var drawer: some View {
        if layout.drawerEdit, let shown = shownEdit {
            MainDrawer(close: { focus.editing = nil }, content: { editPanel(shown) })
        }
    }

    private var shownEdit: (target: ActivityEditTarget, day: ActivityDay)? {
        guard let editing = focus.editing else { return nil }
        let day = e.activityDay(editing.day)
        return ActivityEditPanel.shows(editing.target, in: day) ? (editing.target, day) : nil
    }

    private func editPanel(_ shown: (target: ActivityEditTarget, day: ActivityDay)) -> some View {
        ActivityEditPanel(
            day: shown.day, target: shown.target, categories: e.activityCategories, calendar: e.rangeCalendar,
            calendars: e.calendarChoices(), calendarNames: e.activityCalendarTitles, actions: .engine(e), editing: editTarget
        )
    }

    private func stats(_ data: CalendarPageData, kind: ReportRange) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            CalendarStatsPanel(stats: data.stats, kind: kind, categories: e.activityCategories)
        }
    }

    private var editTarget: Binding<ActivityEditTarget?> {
        Binding(
            get: { focus.editing?.target },
            set: { target in
                guard let target, let day = focus.editing?.day else { return focus.editing = nil }
                focus.editing = CalendarActivityEdit(day: day, target: target)
            }
        )
    }
}
