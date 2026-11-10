import SathiCore
import SwiftUI

struct TrackerOptionsBox: View {
    @Binding var draft: ActivityDraft
    let state: TrackerPromptState
    var compact = false

    var body: some View {
        let size = TrackerSize.of(compact: compact)
        VStack(alignment: .leading, spacing: size.boxSpacing) {
            TrackerForRow(draft: $draft, size: size)
            TrackerOptionRow(label: Copywriter.trackerCategory, size: size) {
                TrackerCategoryMenu(
                    categories: state.categories, selected: draft.category, idPrefix: "tracker.category.", compact: compact,
                    fixedWidth: compact ? nil : UIMetrics.trackerCategoryButtonWidth
                ) { draft.category = $0 }
            }
            TrackerAskRow(draft: $draft, size: size, compact: compact)
            Rectangle().fill(Night.divider).frame(height: UIMetrics.cardBorder)
            TrackerCalendarRow(draft: $draft, calendars: state.calendars, defaultID: state.defaultCalendarID, size: size)
            TrackerQuietRow(draft: $draft, size: size, until: until)
        }
        .trackerBox(padding: size.boxPadding, radius: size.boxRadius)
    }

    private var until: String? {
        guard !compact, let minutes = draft.length.minutes else { return nil }
        let end = state.now.addingTimeInterval(TimeInterval(minutes) * Timing.minute)
        return Copywriter.trackerUntil(end, calendar: state.calendar)
    }
}
