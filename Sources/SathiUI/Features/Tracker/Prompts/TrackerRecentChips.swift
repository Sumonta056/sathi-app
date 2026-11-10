import SathiCore
import SwiftUI

struct TrackerRecentChips: View {
    let state: TrackerPromptState
    let draft: ActivityDraft
    let limit: Int
    let onPick: (ActivityDraft) -> Void

    var body: some View {
        HStack(spacing: UIMetrics.trackerChipSpacing) {
            if let event = state.runningEvent {
                TrackerChip(label: event.title, on: false, id: "tracker.event.chip") {
                    onPick(draft.filled(from: event))
                }
            }
            ForEach(Array(state.recentsShown(limit).enumerated()), id: \.offset) { _, recent in
                TrackerChip(
                    label: recent.text,
                    on: false,
                    id: "tracker.recent.chip",
                    dot: state.categories.first { $0.name == recent.category }?.colorHex
                ) { onPick(draft.filled(from: recent)) }
            }
            Spacer(minLength: 0)
        }
    }
}
