import SathiCore
import SwiftUI

struct PromptQuietRow: View {
    @ObservedObject var model: ActivityPromptModel

    var body: some View {
        HStack(spacing: UIMetrics.promptFooterGap) {
            BuddySwitch(isOn: quiet, accent: Night.tracker, label: Copywriter.trackerQuietSwitch)
                .disabled(isOpen)
                .accessibilityIdentifier("tracker.quiet")
            Text(verbatim: Copywriter.trackerQuietSwitch)
                .font(Typography.tracker(UIMetrics.promptRowFont, .medium))
                .foregroundStyle(Night.chipText)
        }
        .opacity(isOpen ? UIMetrics.trackerDisabledOpacity : 1)
    }

    private var isOpen: Bool { model.draft.length == .open }

    private var quiet: Binding<Bool> {
        Binding(get: { model.draft.quiet && !isOpen }, set: { model.draft.quiet = $0 })
    }
}
