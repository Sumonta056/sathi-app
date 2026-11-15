import SathiCore
import SwiftUI

struct PromptBoxRow<Content: View>: View {
    let label: String
    var labelTop = UIMetrics.promptRowLabelTop
    var labelColor = Night.promptSecondary
    var labelWidth: CGFloat? = UIMetrics.promptRowLabelWidth
    var fills = true
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.promptRowLabelGap) {
            Text(verbatim: label)
                .font(Typography.tracker(UIMetrics.promptRowFont, .medium))
                .foregroundStyle(labelColor)
                .padding(.top, labelTop)
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .leading)
            content
                .frame(maxWidth: fills ? .infinity : nil, alignment: .leading)
                .fixedSize(horizontal: !fills, vertical: false)
        }
    }
}

struct PromptBoxes<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        TrackerFlowLayout(spacing: UIMetrics.promptBoxGap) { content }
    }
}

struct PromptLengthBoxes: View {
    @ObservedObject var model: ActivityPromptModel
    let state: TrackerPromptState

    var body: some View {
        PromptBoxes {
            if let event = state.event, state.kind == .eventAsk {
                PromptBox(label: Copywriter.activityPromptUntil(event.end, calendar: state.calendar), on: true, id: "prompt.for.until") {}
            } else {
                ForEach(ActivityLength.choices, id: \.self) { length in
                    let label = Copywriter.trackerLengthLabel(length)
                    PromptBox(label: label, on: model.draft.length == length, id: "tracker.for." + label) { model.pick(length: length) }
                }
            }
        }
    }
}

struct PromptAskBoxes: View {
    @ObservedObject var model: ActivityPromptModel

    var body: some View {
        PromptBoxes {
            ForEach(Limits.askOffsets, id: \.self) { offset in
                PromptBox(
                    label: Copywriter.trackerAskOffsetShort(offset), on: model.draft.askOffsetMinutes == offset, id: "tracker.ask.\(offset)"
                ) { model.draft.askOffsetMinutes = offset }
            }
        }
    }
}
