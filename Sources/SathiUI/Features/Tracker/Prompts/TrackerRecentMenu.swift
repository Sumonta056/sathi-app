import SathiCore
import SwiftUI

struct TrackerRecentMenu: View {
    let state: TrackerPromptState
    let draft: ActivityDraft
    var compact = false
    let onPick: (ActivityDraft) -> Void
    @State private var isOpen = false

    var body: some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.recentRadius, style: .continuous)
        Button { isOpen.toggle() } label: {
            HStack(spacing: size.recentGap) {
                Image(systemName: "clock")
                    .font(.system(size: size.label, weight: .semibold))
                    .foregroundStyle(Night.muted)
                    .accessibilityHidden(true)
                Text(verbatim: Copywriter.trackerRecent)
                    .font(Typography.tracker(size.label, .bold))
                    .foregroundStyle(Night.label)
                Text(verbatim: Copywriter.trackerRecentHint)
                    .font(Typography.tracker(size.body, .semibold))
                    .foregroundStyle(Night.chipText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TrackerChevron(size: size.chevron)
            }
            .padding(.horizontal, UIMetrics.trackerFieldPadding)
            .frame(height: size.recentHeight)
            .background(shape.fill(Night.trackerInset))
            .overlay(shape.strokeBorder(isOpen ? Night.tracker : Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
            .accessibilityIdentifier("tracker.recent.menu")
        }
        .buttonStyle(TrackerPressStyle())
        .opacity(isEmpty ? UIMetrics.trackerDisabledOpacity : 1)
        .allowsHitTesting(!isEmpty)
        .popover(isPresented: $isOpen, arrowEdge: .bottom) { list }
    }

    private var isEmpty: Bool { state.recents.isEmpty && state.runningEvent == nil }

    var list: TrackerRecentList {
        TrackerRecentList(state: state, draft: draft) {
            isOpen = false
            onPick($0)
        }
    }
}

struct TrackerRecentList: View {
    let state: TrackerPromptState
    let draft: ActivityDraft
    let onPick: (ActivityDraft) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerDropRowGap) {
            Text(verbatim: Copywriter.trackerRecentHeader)
                .font(Typography.tracker(UIMetrics.trackerHintFont, .bold))
                .foregroundStyle(Night.faint)
                .padding(UIMetrics.trackerDropHeaderPadding)
            if let event = state.runningEvent {
                TrackerMenuRow(label: event.title, id: "tracker.event.chip", dot: Night.trackerEvent) {
                    onPick(draft.filled(from: event))
                } trailing: {
                    EmptyView()
                }
            }
            ForEach(Array(state.recentsShown(Limits.recentMax).enumerated()), id: \.offset) { _, recent in
                TrackerMenuRow(label: recent.text, id: "tracker.recent.chip", dot: hex(recent.category)) {
                    onPick(draft.filled(from: recent))
                } trailing: {
                    if let category = recent.category {
                        Text(verbatim: category)
                            .font(Typography.tracker(UIMetrics.trackerHintFont, .medium))
                            .foregroundStyle(Night.faint)
                            .lineLimit(1)
                    }
                }
            }
        }
        .trackerMenuList(width: UIMetrics.trackerRecentMenuWidth)
    }

    private func hex(_ category: String?) -> Color? {
        state.categories.first { $0.name == category }.map { Color(hex: $0.colorHex) }
    }
}
