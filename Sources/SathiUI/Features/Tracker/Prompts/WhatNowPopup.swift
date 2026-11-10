import SathiCore
import SwiftUI

struct WhatNowPopup: View {
    let state: TrackerPromptState
    @ObservedObject private var form: TrackerDraftForm
    @State private var picked: Date?
    @State private var optionsOpen = false

    init(state: TrackerPromptState, form: TrackerDraftForm? = nil) {
        self.state = state
        self.form = form ?? TrackerDraftForm(state.draft)
        _picked = State(initialValue: state.switchTimes.last)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPopupSpacing) {
            TrackerHeader(icon: "pencil", eyebrow: eyebrow, title: Copywriter.trackerWhatAreYouDoingNow, detail: endsLine)
            if let resume = state.resume {
                TrackerPrimaryButton(label: Copywriter.trackerContinue(resume.text), id: "tracker.continue") {
                    state.actions.continueLast(picked)
                }
                .keyboardShortcut(.defaultAction)
            }
            LazyTextField(placeholder: Copywriter.trackerFieldPlaceholder, text: $form.draft.text, startsEditing: true, onSubmit: submit)
                .modifier(QuickTextLimit(text: $form.draft.text, limit: Limits.activityTextMax))
                .trackerField()
            TrackerRecentChips(state: state, draft: form.draft, limit: Limits.recentInCorner) { state.actions.start($0, picked) }
            TrackerForRow(draft: $form.draft)
            TrackerCalendarRow(draft: $form.draft, calendars: state.calendars, defaultID: state.defaultCalendarID)
            TrackerQuietRow(draft: $form.draft)
            if state.showsSwitchRow {
                TrackerSwitchRow(times: state.switchTimes, picked: $picked, calendar: state.calendar)
            }
            TrackerSummaryLine(draft: form.draft, categories: state.categories, open: $optionsOpen)
            if optionsOpen { TrackerOptionsPanel(draft: $form.draft, categories: state.categories) }
            HStack(spacing: UIMetrics.trackerButtonSpacing) {
                TrackerPrimaryButton(label: Copywriter.trackerStart, id: "tracker.start", action: start)
                TrackerSecondaryButton(
                    label: Copywriter.trackerSkip, id: "tracker.skip", width: UIMetrics.trackerSkipWidth
                ) { state.actions.skip(picked) }
            }
            Text(verbatim: [Copywriter.trackerKeysOptions, Copywriter.trackerKeysStart, Copywriter.trackerKeysSkip].joined(separator: "   "))
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
        }
        .trackerCornerCard()
        .onExitCommand { state.actions.skip(picked) }
    }

    private var eyebrow: String {
        guard state.showsSwitchRow, let last = state.lastActivity else {
            return Copywriter.trackerWhatNowEyebrow(state.now, calendar: state.calendar)
        }
        return Copywriter.trackerDoneEyebrow(last.text, state.now, calendar: state.calendar)
    }

    private var endsLine: String? {
        guard state.showsSwitchRow, let last = state.lastActivity, let at = picked else { return nil }
        return Copywriter.trackerEndsAt(last.text, at, isNow: at == state.switchTimes.last, calendar: state.calendar)
    }

    func submit() {
        if form.draft.committed == nil, state.resume != nil {
            state.actions.continueLast(picked)
        } else {
            start()
        }
    }

    private func start() {
        guard let committed = form.draft.committed else { return }
        state.actions.start(committed, picked)
    }
}
