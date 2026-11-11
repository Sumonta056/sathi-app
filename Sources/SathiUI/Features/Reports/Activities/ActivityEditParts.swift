import SathiCore
import SwiftUI

extension PromptBoxLook {
    static func activityEdit(_ on: Color) -> PromptBoxLook {
        PromptBoxLook(
            height: UIMetrics.activitiesChipHeight, font: UIMetrics.activitiesChipFont, padding: UIMetrics.activitiesChipPadding,
            offFill: .clear, offLine: Night.fieldBorder, offText: Night.chipText, onFill: on
        )
    }
}

struct ActivityFieldLabel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.activitiesFieldLabelFont, .heavy))
            .foregroundStyle(Night.muted)
    }
}

struct ActivityEditTimes: View {
    @Binding var draft: ActivityEditDraft
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesEditGap) {
            HStack(alignment: .top, spacing: UIMetrics.activitiesChipGap) {
                column(Copywriter.activitiesFieldStart) { TimeMenu(minutes: $draft.startMinutes, accent: Night.tracker) }
                column(Copywriter.activitiesFieldEnd) { TimeMenu(minutes: $draft.endMinutes, accent: Night.tracker) }
                column(Copywriter.activitiesFieldLength) {
                    Text(verbatim: Copywriter.activitiesLength(draft.lengthSeconds))
                        .font(Typography.tracker(UIMetrics.activitiesGapFont, .bold))
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity, minHeight: UIMetrics.activitiesFieldHeight)
                        .background(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
                            .fill(accent.opacity(UIMetrics.activitiesRowTint)))
                        .accessibilityIdentifier("activity.edit.length")
                }
            }
            TrackerFlowLayout(spacing: UIMetrics.activitiesChipGap) {
                ForEach(Limits.activityEditLengthChips, id: \.self) { minutes in
                    PromptBox(
                        label: Copywriter.activitiesLength(TimeInterval(minutes) * Timing.minute), on: false,
                        id: "activity.length.\(minutes)", look: .activityEdit(accent)
                    ) { draft.setLength(minutes) }
                }
                Text(verbatim: Copywriter.activitiesSetsEnd)
                    .font(Typography.tracker(UIMetrics.activitiesChipFont, .medium))
                    .foregroundStyle(Night.faint)
                    .frame(height: UIMetrics.activitiesChipHeight)
            }
        }
    }

    private func column(_ label: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesFieldGap) {
            ActivityFieldLabel(text: label)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
