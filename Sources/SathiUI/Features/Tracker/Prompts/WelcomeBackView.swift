import SathiCore
import SwiftUI

struct WelcomeBackView: View {
    let state: TrackerPromptState
    @State private var draft: ActivityDraft
    @State private var somethingNew = false

    init(state: TrackerPromptState) {
        self.state = state
        _draft = State(initialValue: state.draft)
    }

    var body: some View {
        let size = TrackerSize.center
        VStack(alignment: .leading, spacing: UIMetrics.trackerWelcomeSpacing) {
            TrackerHeader(icon: "house", eyebrow: eyebrow, title: Copywriter.trackerWelcomeBack, compact: false)
            if let last = state.lastActivity {
                TrackerPrimaryButton(
                    label: Copywriter.trackerBackTo(last.text), id: "tracker.back", height: size.buttonHeight,
                    radius: size.buttonRadius, font: size.button, dot: true, key: Copywriter.trackerEnterKey
                ) { state.actions.backToLast() }
                    .keyboardShortcut(.defaultAction)
            }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                if somethingNew {
                    LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $draft.text, startsEditing: true, onSubmit: start)
                        .modifier(QuickTextLimit(text: $draft.text, limit: Limits.activityTextMax))
                        .trackerField()
                } else {
                    row(Copywriter.trackerSomethingNew, "tracker.new") { somethingNew = true }
                }
                if state.away?.fromIdle == true {
                    row(Copywriter.trackerIWasHere, "tracker.here") { state.actions.iWasHere() }
                }
            }
            WelcomePlaces(state: state)
            if !state.loggedWhileAway.isEmpty { WelcomeWhileAway(state: state) }
            TrackerHint(text: Copywriter.trackerWelcomeKeys)
        }
        .trackerCenterCard(width: UIMetrics.trackerWelcomeCard)
        .onExitCommand { state.actions.close() }
    }

    private var eyebrow: String {
        guard let away = state.away else { return Copywriter.trackerAway.uppercased() }
        return Copywriter.trackerAwayEyebrow(away.start, away.end, calendar: state.calendar)
    }

    private func row(_ label: String, _ id: String, action: @escaping () -> Void) -> some View {
        TrackerSecondaryButton(
            label: label, id: id, height: UIMetrics.trackerWelcomeRowHeight, radius: TrackerSize.center.buttonRadius,
            font: UIMetrics.trackerWelcomeRowFont, weight: .bold, color: Night.text, action: action
        )
    }

    private func start() {
        guard let committed = draft.committed else { return }
        state.actions.start(committed, nil)
    }
}
