import SathiCore
import SwiftUI

struct ActivityEditAwaySwitch: View {
    @Binding var draft: ActivityEditDraft
    var defaultCategory: String?

    var body: some View {
        HStack(spacing: UIMetrics.activitiesChipGap) {
            ActivityFieldLabel(text: Copywriter.trackerAway)
                .frame(maxWidth: .infinity, alignment: .leading)
            BuddySwitch(
                isOn: Binding(get: { draft.isAway }, set: { switched($0) }),
                accent: Night.sprout, label: Copywriter.trackerAway
            )
            .accessibilityIdentifier("activity.away.switch")
        }
    }

    private func switched(_ on: Bool) {
        draft.setAway(on)
        if !on, draft.category == nil { draft.category = defaultCategory }
    }
}
