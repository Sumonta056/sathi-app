import SathiCore
import SwiftUI

struct EventAskPopup: View {
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            TrackerHeader(
                icon: "calendar",
                eyebrow: Copywriter.trackerFromCalendar(event?.start ?? state.now, calendar: state.calendar),
                title: Copywriter.trackerEventAsk(event?.title ?? ""),
                detail: event.map { Copywriter.trackerSpan($0.start, $0.end, calendar: state.calendar) }
            )
            TrackerCategoryRows(
                categories: state.categories, selected: state.draft.category, idPrefix: "tracker.eventCategory."
            ) { state.actions.pickEventCategory($0) }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                TrackerPrimaryButton(label: Copywriter.trackerYesLogIt, id: "tracker.yes") { state.actions.answerEvent(true) }
                TrackerSecondaryButton(
                    label: Copywriter.trackerNo, id: "tracker.no", width: UIMetrics.trackerSkipWidth
                ) { state.actions.answerEvent(false) }
            }
        }
        .trackerCornerCard()
    }

    private var event: CalendarEventInfo? { state.event }
}
