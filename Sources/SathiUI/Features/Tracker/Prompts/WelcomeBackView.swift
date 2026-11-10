import SathiCore
import SwiftUI

struct WelcomeBackView: View {
    let state: TrackerPromptState
    @ObservedObject private var form: WelcomeForm
    @State private var draft: ActivityDraft
    @State private var somethingNew = false

    init(state: TrackerPromptState, form: WelcomeForm? = nil) {
        self.state = state
        self.form = form ?? WelcomeForm(state)
        _draft = State(initialValue: state.draft)
    }

    var body: some View {
        let size = TrackerSize.center
        VStack(alignment: .leading, spacing: UIMetrics.trackerWelcomeSpacing) {
            TrackerHeader(icon: "house", eyebrow: eyebrow, title: Copywriter.trackerWelcomeBack, compact: false)
            WelcomePlaces(state: state, form: form)
            WelcomeStep(number: 2, text: Copywriter.trackerWhatNow)
            if let last = state.lastActivity {
                TrackerPrimaryButton(
                    label: Copywriter.trackerContinue(last.text), id: "tracker.back", height: size.buttonHeight,
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
                    row(Copywriter.trackerStartSomethingNew, "tracker.new") { somethingNew = true }
                }
                if state.away?.fromIdle == true {
                    row(Copywriter.trackerIWasHere, "tracker.here") { state.actions.iWasHere() }
                }
            }
            if !state.loggedWhileAway.isEmpty { WelcomeWhileAway(state: state) }
            TrackerHint(text: state.lastActivity == nil ? Copywriter.trackerWelcomeEsc : Copywriter.trackerWelcomeKeys)
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

struct WelcomeStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: UIMetrics.trackerChipSpacing) {
            Text(verbatim: "\(number)").foregroundStyle(Night.tracker)
            Text(verbatim: "·").foregroundStyle(Night.label)
            Text(verbatim: text).foregroundStyle(Night.label)
        }
        .font(Typography.tracker(UIMetrics.trackerPillFont, .bold))
        .accessibilityElement(children: .combine)
    }
}
