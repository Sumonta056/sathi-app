import SathiCore
import SwiftUI

struct PromptFooter: View {
    let screen: ActivityPromptScreen
    let commands: PromptCommands

    var body: some View {
        HStack(spacing: UIMetrics.promptFooterGap) {
            Button(action: commands.skip) {
                Text(verbatim: Copywriter.trackerSkip)
                    .font(Typography.tracker(UIMetrics.promptButtonFont, .semibold))
                    .foregroundStyle(Night.promptSecondary)
                    .padding(.horizontal, UIMetrics.promptSkipPadding)
                    .frame(height: UIMetrics.promptButtonHeight)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(skipID)
            }
            .buttonStyle(TrackerPressStyle())
            .modifier(PromptKey.skip)
            if let keep = screen.keepLabel {
                Button(action: commands.keep) {
                    Text(verbatim: keep)
                        .font(Typography.tracker(UIMetrics.promptButtonFont, .semibold))
                        .foregroundStyle(Night.text)
                        .lineLimit(1)
                        .padding(.horizontal, UIMetrics.promptKeepPadding)
                        .frame(height: UIMetrics.promptButtonHeight)
                        .overlay(shape.strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
                        .contentShape(shape)
                        .accessibilityIdentifier("prompt.keep")
                }
                .buttonStyle(TrackerPressStyle())
            }
            Button(action: commands.start) {
                Text(verbatim: screen.startLabel)
                    .font(Typography.tracker(UIMetrics.promptStartFont, .heavy))
                    .foregroundStyle(Night.onAccent)
                    .lineLimit(1)
                    .padding(.horizontal, UIMetrics.promptStartPadding)
                    .frame(height: UIMetrics.promptButtonHeight)
                    .background(shape.fill(Night.reason(screen.reason)))
                    .contentShape(shape)
                    .accessibilityIdentifier("tracker.start")
            }
            .buttonStyle(TrackerPressStyle())
            .modifier(PromptKey.start)
        }
        .fixedSize()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.promptButtonRadius, style: .continuous)
    }

    private var skipID: String {
        switch screen.skip {
        case .skip: "tracker.skip"
        case .close: "tracker.close"
        case .answerNo: "tracker.no"
        }
    }
}
