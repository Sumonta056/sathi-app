import SathiCore
import SwiftUI

struct CenterPromptView: View {
    let state: TrackerPromptState
    @ObservedObject private var form: TrackerDraftForm
    @State private var optionsOpen = false

    init(state: TrackerPromptState, form: TrackerDraftForm? = nil) {
        self.state = state
        self.form = form ?? TrackerDraftForm(state.draft)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerPopupRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            LazyTextField(placeholder: Copywriter.trackerWhatAreYouDoing, text: $form.draft.text, startsEditing: true, onSubmit: start)
                .modifier(QuickTextLimit(text: $form.draft.text, limit: Limits.activityTextMax))
                .font(.system(size: UIMetrics.trackerCenterInputFont, weight: .semibold, design: .rounded))
                .padding(UIMetrics.trackerCenterInputPadding)
            TrackerRecentChips(state: state, draft: form.draft, limit: Limits.recentInCenter) { state.actions.start($0, nil) }
            TrackerForRow(draft: $form.draft)
            TrackerCalendarRow(draft: $form.draft, calendars: state.calendars)
            TrackerQuietRow(draft: $form.draft)
            TrackerSummaryLine(draft: form.draft, categories: state.categories, open: $optionsOpen)
            if optionsOpen { TrackerOptionsPanel(draft: $form.draft, categories: state.categories) }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                TrackerPrimaryButton(label: Copywriter.trackerStart, id: "tracker.start", action: start)
                TrackerSecondaryButton(
                    label: "Close", id: "tracker.close", width: UIMetrics.trackerSkipWidth
                ) { state.actions.close() }
            }
        }
        .padding(UIMetrics.trackerPopupPadding)
        .frame(width: UIMetrics.trackerCenterWidth)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        .environment(\.colorScheme, .dark)
        .onExitCommand { state.actions.close() }
    }

    private func start() {
        guard let committed = form.draft.committed else { return }
        state.actions.start(committed, nil)
    }
}
