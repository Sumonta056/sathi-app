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
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerPopupRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            TrackerHeader(icon: "hand.wave", eyebrow: eyebrow, title: Copywriter.trackerWelcomeBack)
            if let last = state.lastActivity {
                TrackerPrimaryButton(label: Copywriter.trackerBackTo(last.text), id: "tracker.back") {
                    state.actions.backToLast()
                }
                .keyboardShortcut(.defaultAction)
            }
            if somethingNew {
                LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $draft.text, startsEditing: true, onSubmit: start)
                    .modifier(QuickTextLimit(text: $draft.text, limit: Limits.activityTextMax))
                    .trackerField()
            } else {
                TrackerSecondaryButton(label: Copywriter.trackerSomethingNew, id: "tracker.new") { somethingNew = true }
            }
            if state.away?.fromIdle == true {
                TrackerSecondaryButton(label: Copywriter.trackerIWasHere, id: "tracker.here") { state.actions.iWasHere() }
            }
            places
            if !state.loggedWhileAway.isEmpty { whileAway }
        }
        .padding(UIMetrics.trackerPopupPadding)
        .frame(width: UIMetrics.trackerWelcomeWidth)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
        .environment(\.colorScheme, .dark)
        .onExitCommand { state.actions.close() }
    }

    private var eyebrow: String {
        guard let away = state.away else { return Copywriter.trackerAway.uppercased() }
        return Copywriter.trackerAwayEyebrow(away.start, away.end, calendar: state.calendar)
    }

    private var places: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerNoteSpacing) {
            Text(verbatim: Copywriter.trackerWhereWereYou)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                ForEach(AwayPlace.choices, id: \.self) { place in
                    TrackerChip(
                        label: Copywriter.trackerAwayPlace(place),
                        on: state.away?.place == place,
                        id: "tracker.place." + place.rawValue
                    ) { state.actions.pickPlace(place) }
                }
            }
        }
    }

    private var whileAway: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerNoteSpacing) {
            Text(verbatim: Copywriter.trackerWhileAway)
                .font(Typography.eyebrow)
                .tracking(UIMetrics.trackerEyebrowTracking)
                .foregroundStyle(Night.muted)
            ForEach(state.loggedWhileAway, id: \.id) { row($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIMetrics.trackerInsetPadding)
        .background(RoundedRectangle(cornerRadius: UIMetrics.trackerInsetRadius, style: .continuous).fill(Night.trackerInset))
    }

    private func row(_ a: Activity) -> some View {
        HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: a.text).font(Typography.rowLabel).foregroundStyle(Night.text).lineLimit(1)
                Text(verbatim: Copywriter.trackerSpan(a.start, a.end, calendar: state.calendar) + " · " + Copywriter.trackerLogged)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Spacer(minLength: 0)
            if let eventID = a.sourceEventID {
                TrackerChip(label: Copywriter.trackerNotAttending, on: false, id: "tracker.notAttending") {
                    state.actions.notAttending(eventID)
                }
            }
        }
    }

    private func start() {
        guard let committed = draft.committed else { return }
        state.actions.start(committed, nil)
    }
}
