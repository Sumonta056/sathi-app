import SathiCore
import SwiftUI

struct CenterPromptView: View {
    let state: TrackerPromptState
    @ObservedObject private var form: TrackerDraftForm

    init(state: TrackerPromptState, form: TrackerDraftForm? = nil) {
        self.state = state
        self.form = form ?? TrackerDraftForm(state.draft)
    }

    var body: some View {
        let size = TrackerSize.center
        VStack(alignment: .leading, spacing: size.spacing) {
            TrackerHeader(
                icon: "pencil",
                eyebrow: Copywriter.trackerLogEyebrow(state.now, calendar: state.calendar),
                title: Copywriter.trackerWhatAreYouDoingNow,
                compact: false
            )
            LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $form.draft.text, startsEditing: true, onSubmit: start)
                .modifier(QuickTextLimit(text: $form.draft.text, limit: Limits.activityTextMax))
                .trackerField(compact: false)
            TrackerRecentMenu(state: state, draft: form.draft) { state.actions.start($0, nil) }
            TrackerOptionsBox(draft: $form.draft, state: state)
            HStack(spacing: size.buttonGap) {
                TrackerPrimaryButton(
                    label: Copywriter.trackerStart, id: "tracker.start",
                    height: size.buttonHeight, radius: size.buttonRadius, font: size.button, action: start
                )
                TrackerSecondaryButton(
                    label: Copywriter.trackerClose, id: "tracker.close", height: size.buttonHeight,
                    width: size.sideButton, radius: size.buttonRadius, font: size.button
                ) { state.actions.close() }
            }
            TrackerHint(text: Copywriter.trackerCenterKeys(state.shortcut.map(Copywriter.trackerShortcut)))
        }
        .trackerCenterCard()
        .onExitCommand { state.actions.close() }
    }

    private func start() {
        guard let committed = form.draft.committed else { return }
        state.actions.start(committed, nil)
    }
}
