import SathiCore
import SwiftUI

struct TrackerOptionRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
            Text(verbatim: label)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .frame(width: UIMetrics.trackerRowLabelWidth, alignment: .leading)
            content
            Spacer(minLength: 0)
        }
    }
}

struct TrackerForRow: View {
    @Binding var draft: ActivityDraft

    var body: some View {
        TrackerOptionRow(label: Copywriter.trackerFor) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                ForEach(ActivityLength.choices, id: \.self) { length in
                    TrackerChip(
                        label: Copywriter.trackerLengthLabel(length),
                        on: draft.length == length,
                        id: "tracker.for." + Copywriter.trackerLengthLabel(length)
                    ) { draft = draft.with(length: length) }
                }
            }
        }
    }
}

struct TrackerQuietRow: View {
    @Binding var draft: ActivityDraft

    var body: some View {
        HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
            Text(verbatim: Copywriter.trackerQuietSwitch)
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
            Spacer(minLength: 0)
            BuddySwitch(isOn: quiet, accent: Night.tracker, label: Copywriter.trackerQuietSwitch)
                .accessibilityIdentifier("tracker.quiet")
        }
        .opacity(draft.length == .open ? UIMetrics.trackerDisabledOpacity : 1)
        .allowsHitTesting(draft.length != .open)
    }

    private var quiet: Binding<Bool> {
        Binding(get: { draft.quiet && draft.length != .open }, set: { draft.quiet = $0 })
    }
}

struct TrackerSummaryLine: View {
    let draft: ActivityDraft
    let categories: [ActivityCategory]
    @Binding var open: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerSummaryRadius, style: .continuous)
        Button { open.toggle() } label: {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                if let hex = categories.first(where: { $0.name == draft.category })?.colorHex {
                    Circle().fill(Color(hex: hex)).frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot)
                }
                Text(verbatim: Copywriter.trackerSummary(category: draft.category, askOffsetMinutes: draft.askOffsetMinutes))
                    .font(Typography.hint)
                    .foregroundStyle(Night.chipText)
                Spacer(minLength: 0)
                Image(systemName: open ? "chevron.up" : "chevron.down")
                    .font(.system(size: UIMetrics.blockChevron, weight: .heavy))
                    .foregroundStyle(Night.muted)
            }
            .padding(UIMetrics.trackerSummaryPadding)
            .background(shape.fill(Night.trackerInset))
            .contentShape(shape)
            .accessibilityIdentifier("tracker.summary")
        }
        .buttonStyle(.plain)
    }
}

struct TrackerOptionsPanel: View {
    @Binding var draft: ActivityDraft
    let categories: [ActivityCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerNoteSpacing) {
            Text(verbatim: Copywriter.trackerCategory)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            TrackerCategoryRows(
                categories: categories, selected: draft.category, idPrefix: "tracker.category."
            ) { draft.category = $0 }
            Text(verbatim: Copywriter.trackerAskMe)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                ForEach(Limits.askOffsets, id: \.self) { offset in
                    TrackerChip(
                        label: Copywriter.trackerAskOffsetLabel(offset),
                        on: draft.askOffsetMinutes == offset,
                        id: "tracker.ask.\(offset)"
                    ) { draft.askOffsetMinutes = offset }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIMetrics.trackerInsetPadding)
        .background(RoundedRectangle(cornerRadius: UIMetrics.trackerInsetRadius, style: .continuous).fill(Night.trackerWell))
    }
}
