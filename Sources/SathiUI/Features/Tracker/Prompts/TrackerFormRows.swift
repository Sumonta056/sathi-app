import SathiCore
import SwiftUI

struct TrackerOptionRow<Content: View>: View {
    let label: String
    let size: TrackerSize
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: size.rowGap) {
            Text(verbatim: label)
                .font(Typography.tracker(size.label, .bold))
                .foregroundStyle(Night.label)
                .frame(width: size.labelWidth, alignment: .leading)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrackerForRow: View {
    @Binding var draft: ActivityDraft
    let size: TrackerSize

    var body: some View {
        TrackerOptionRow(label: Copywriter.trackerFor, size: size) {
            ForEach(ActivityLength.choices, id: \.self) { length in
                TrackerChip(
                    label: Copywriter.trackerLengthLabel(length),
                    on: draft.length == length,
                    id: "tracker.for." + Copywriter.trackerLengthLabel(length),
                    height: size.chipHeight, padding: size.chipPadding, font: size.chipFont
                ) { draft = draft.with(length: length) }
            }
        }
    }
}

struct TrackerAskRow: View {
    @Binding var draft: ActivityDraft
    let size: TrackerSize
    let compact: Bool

    var body: some View {
        TrackerOptionRow(label: Copywriter.trackerAskMe, size: size) {
            ForEach(Limits.askOffsets, id: \.self) { offset in
                TrackerChip(
                    label: compact ? Copywriter.trackerAskOffsetShort(offset) : Copywriter.trackerAskOffsetLabel(offset),
                    on: draft.askOffsetMinutes == offset,
                    id: "tracker.ask.\(offset)",
                    height: size.chipHeight, padding: size.chipPadding, font: size.chipFont
                ) { draft.askOffsetMinutes = offset }
            }
        }
    }
}

struct TrackerQuietRow: View {
    @Binding var draft: ActivityDraft
    let size: TrackerSize
    var until: String?

    var body: some View {
        HStack(spacing: size.toggleGap) {
            Text(verbatim: Copywriter.trackerQuietSwitch)
                .font(Typography.tracker(size.body, .semibold))
                .foregroundStyle(Night.text)
            if let until {
                Text(verbatim: until)
                    .font(Typography.tracker(UIMetrics.trackerDetailFont, .medium))
                    .foregroundStyle(Night.faint)
            }
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
