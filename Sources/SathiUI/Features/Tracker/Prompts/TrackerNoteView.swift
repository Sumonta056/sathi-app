import SathiCore
import SwiftUI

struct TrackerNoteView: View {
    let state: TrackerNoteState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            TrackerHeader(
                icon: "calendar",
                eyebrow: Copywriter.trackerFromCalendar(event.start, calendar: state.calendar),
                title: title,
                detail: Copywriter.trackerEventSpan(event, calendarTitle: state.calendarTitle ?? "", calendar: state.calendar)
            )
            if let ended = state.endedText {
                Text(verbatim: Copywriter.trackerEventEnded(ended, at: event.start, calendar: state.calendar))
                    .font(Typography.hint)
                    .foregroundStyle(Night.chipText)
            }
            if !isAlsoNow { categories }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                if isAlsoNow {
                    TrackerPrimaryButton(
                        label: Copywriter.trackerSwitch, id: "tracker.note.switch", height: UIMetrics.trackerNoteButtonHeight
                    ) { state.actions.switchToEvent() }
                } else {
                    TrackerSecondaryButton(
                        label: Copywriter.trackerUndo, id: "tracker.note.undo", height: UIMetrics.trackerNoteButtonHeight
                    ) { state.actions.undo() }
                }
                TrackerSecondaryButton(
                    label: Copywriter.trackerNotAttending, id: "tracker.note.notAttending", height: UIMetrics.trackerNoteButtonHeight
                ) { state.actions.notAttending() }
            }
        }
        .trackerCornerCard()
    }

    private var event: CalendarEventInfo { state.note.event }

    private var isAlsoNow: Bool {
        if case .alsoNow = state.note { return true }
        return false
    }

    private var title: String {
        isAlsoNow ? Copywriter.trackerAlsoNow(event.title) : event.title
    }

    private var categories: some View {
        TrackerCategoryRows(
            categories: state.categories, selected: state.category, idPrefix: "tracker.note.category."
        ) { state.actions.pickCategory($0) }
    }
}
