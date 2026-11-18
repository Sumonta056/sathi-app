import SathiCore
import SwiftUI

struct PromptCalendarBoxes: View {
    @ObservedObject var model: ActivityPromptModel
    let state: TrackerPromptState
    let screen: ActivityPromptScreen

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptRowLabelGap) {
            boxes
            if let note {
                Text(verbatim: note)
                    .font(Typography.tracker(UIMetrics.promptNoteFont, .medium))
                    .foregroundStyle(Night.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var info: TrackerCalendarInfo { model.calendars }
    private var readOnly: Bool { screen.reason == .event }

    @ViewBuilder private var boxes: some View {
        if readOnly {
            if info.access == .allowed, !info.calendars.isEmpty { choices }
        } else {
            access
        }
    }

    @ViewBuilder private var access: some View {
        switch info.access {
        case .notAsked:
            PromptBox(label: Copywriter.activityPromptAllowCalendar, on: false, id: "prompt.calendar.allow") {
                model.allowCalendar(state.actions.allowCalendar)
            }
        case .denied:
            PromptBox(label: Copywriter.blockOpenSettings, on: false, id: "tracker.calendar.openSettings") {
                state.actions.openCalendarSettings()
            }
        case .allowed where info.calendars.isEmpty:
            Text(verbatim: Copywriter.trackerNoCalendars)
                .font(Typography.tracker(UIMetrics.promptRowFont, .medium))
                .foregroundStyle(Night.faint)
                .padding(.top, UIMetrics.promptRowLabelTop)
                .accessibilityIdentifier("tracker.calendar.none")
        case .allowed:
            choices
        }
    }

    private var counts: [Int] {
        let top = min(Limits.promptCalendarsShown, info.calendars.count)
        let low = model.draft.calendarID == nil ? 0 : min(1, top)
        return Array(stride(from: top, through: low, by: -1))
    }

    @ViewBuilder private var choices: some View {
        if model.showsAllCalendars {
            PromptBoxes { row(info.calendars) }
        } else {
            ViewThatFits(in: .horizontal) {
                ForEach(counts, id: \.self) { n in
                    HStack(spacing: UIMetrics.promptBoxGap) { row(shown(n)) }
                }
            }
        }
    }

    private func shown(_ n: Int) -> [CalendarChoice] {
        CalendarChips.shown(info.calendars, picked: model.draft.calendarID, all: false, limit: n)
    }

    @ViewBuilder private func row(_ shown: [CalendarChoice]) -> some View {
        let hidden = info.calendars.count - shown.count
        ForEach(shown) { c in
            let color = Night.category(c.colorHex)
            PromptBox(
                label: CalendarChips.label(c, in: info.calendars), on: !readOnly && model.draft.calendarID == c.id,
                id: "prompt.calendar." + c.id, dot: color, look: .solid(color)
            ) { model.draft.calendarID = c.id }
                .disabled(readOnly)
        }
        PromptBox(
            label: Copywriter.activityPromptCalendarNone, on: readOnly || model.draft.calendarID == nil, id: "prompt.calendar.none",
            dot: Night.promptDim, look: .solid(Night.promptSecondary)
        ) { model.draft.calendarID = nil }
            .disabled(readOnly)
        if hidden > 0, !readOnly {
            PromptBox(label: Copywriter.activityPromptCalendarMore(hidden), on: false, id: "prompt.calendar.more") {
                model.showsAllCalendars = true
            }
        }
    }

    private var note: String? {
        if readOnly { return screen.calendarNote }
        guard info.access == .allowed, !info.calendars.isEmpty else { return nil }
        guard let picked = info.calendars.first(where: { $0.id == model.draft.calendarID }) else { return Copywriter.activityPromptNoEvent }
        return Copywriter.activityPromptCalendarGoes(picked.title)
    }
}
