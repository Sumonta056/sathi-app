import SathiCore
import SwiftUI

struct PromptRecentPane: View {
    @ObservedObject var model: ActivityPromptModel
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptPaneGap) {
            head
            ForEach(Array(shown.enumerated()), id: \.offset) { index, item in
                PromptRecentCard(item: item, index: index, filled: model.draft.text == item.text) { pick(item) }
            }
            Spacer(minLength: 0)
            if !model.showsAll, items.count > Limits.recentShown { showAll }
        }
        .padding(UIMetrics.promptPanePadding)
        .frame(width: UIMetrics.promptPaneWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Night.promptPane)
    }

    private var items: [PromptRecentItem] {
        let event = state.runningEvent.map { PromptRecentItem(event: $0, calendar: state.calendar) }
        let recents = state.recents.prefix(Limits.recentMax).map { PromptRecentItem(recent: $0, categories: state.categories) }
        return (event.map { [$0] } ?? []) + recents
    }

    private var shown: [PromptRecentItem] {
        Array(items.prefix(model.showsAll ? items.count : Limits.recentShown))
    }

    private func pick(_ item: PromptRecentItem) {
        switch item.source {
        case let .recent(recent): model.fill(recent)
        case let .event(event): model.fill(event)
        }
    }

    private var head: some View {
        HStack {
            Text(verbatim: Copywriter.activityPromptRecentLabel)
                .font(Typography.tracker(UIMetrics.promptTagFont, .bold))
                .tracking(UIMetrics.promptTagTracking)
                .foregroundStyle(Night.label)
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.activityPromptTapToFill)
                .font(Typography.tracker(UIMetrics.promptTagFont, .medium))
                .foregroundStyle(Night.faint)
        }
        .padding(UIMetrics.promptPaneHeadPadding)
    }

    private var showAll: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptShowAllRadius, style: .continuous)
        return Button { model.showsAll = true } label: {
            Text(verbatim: Copywriter.activityPromptShowAll(min(state.recents.count, Limits.recentMax)))
                .font(Typography.tracker(UIMetrics.promptRowFont, .medium))
                .foregroundStyle(Night.promptSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: UIMetrics.promptShowAllHeight)
                .overlay(shape.strokeBorder(
                    Night.promptDim,
                    style: StrokeStyle(lineWidth: UIMetrics.promptBorder, dash: UIMetrics.promptShowAllDash)
                ))
                .contentShape(shape)
                .accessibilityIdentifier("prompt.showAll")
        }
        .buttonStyle(TrackerPressStyle())
    }
}
