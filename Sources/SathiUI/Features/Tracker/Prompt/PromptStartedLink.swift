import SathiCore
import SwiftUI

struct PromptStartedLink: View {
    @ObservedObject var model: ActivityPromptModel
    let choices: [Date]
    let calendar: Calendar

    var body: some View {
        HStack(spacing: UIMetrics.promptLinkGap) {
            if !choices.isEmpty {
                Button { model.showsStarted.toggle() } label: {
                    Text(verbatim: Copywriter.activityPromptStarted(model.started == choices.last ? nil : model.started, calendar: calendar))
                        .font(Typography.tracker(UIMetrics.promptLinkFont, .medium))
                        .foregroundStyle(Night.promptSecondary)
                        .underline(color: Night.promptDim)
                        .accessibilityIdentifier("prompt.started")
                }
                .buttonStyle(.plain)
            }
            Text(verbatim: Copywriter.activityPromptEscSkip)
                .font(Typography.tracker(UIMetrics.promptLinkFont, .medium))
                .foregroundStyle(Night.promptDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PromptStartedBoxes: View {
    @ObservedObject var model: ActivityPromptModel
    let choices: [Date]
    let calendar: Calendar

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.promptBoxGap) {
            Text(verbatim: Copywriter.activityPromptReallyStarted)
                .font(Typography.tracker(UIMetrics.promptLinkFont, .medium))
                .foregroundStyle(Night.promptSecondary)
                .padding(.top, UIMetrics.promptRowLabelTop)
                .fixedSize()
            PromptBoxes {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, time in
                    PromptBox(label: label(time), on: model.started == time, id: "prompt.started.\(index)") { model.started = time }
                }
            }
        }
        .padding(UIMetrics.promptStartedPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.promptStartedRadius, style: .continuous).fill(Night.promptHeader))
        .overlay(
            RoundedRectangle(cornerRadius: UIMetrics.promptStartedRadius, style: .continuous)
                .strokeBorder(Night.promptCardLine, lineWidth: UIMetrics.promptBorder)
        )
    }

    private func label(_ time: Date) -> String {
        time == choices.last ? Copywriter.trackerNow : Copywriter.trackerClock(time, calendar: calendar)
    }
}
