import SathiCore
import SwiftUI

struct PromptFooter: View {
    let screen: ActivityPromptScreen
    let commands: PromptCommands

    var body: some View {
        HStack(spacing: UIMetrics.promptFooterGap) {
            Button(action: commands.skip) {
                Text(verbatim: screen.skip == .later ? Copywriter.todoLater : Copywriter.trackerSkip)
                    .font(Typography.tracker(UIMetrics.promptButtonFont, .semibold))
                    .foregroundStyle(Night.promptSecondary)
                    .padding(.horizontal, UIMetrics.promptSkipPadding)
                    .frame(height: UIMetrics.promptButtonHeight)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(skipID)
            }
            .buttonStyle(TrackerPressStyle())
            .modifier(PromptKey.skip)
            if let label = screen.doneLabel { PromptTodoDoneButton(label: label, action: commands.doneTodo) }
            Button(action: commands.start) {
                Text(verbatim: startLabel)
                    .font(Typography.tracker(UIMetrics.promptStartFont, .heavy))
                    .foregroundStyle(primary ? Night.onAccent : Night.text)
                    .lineLimit(1)
                    .padding(.horizontal, UIMetrics.promptStartPadding)
                    .frame(height: UIMetrics.promptButtonHeight)
                    .background(shape.fill(primary ? fill : Color.clear))
                    .overlay(shape.strokeBorder(primary ? Color.clear : Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
                    .contentShape(shape)
                    .accessibilityIdentifier("tracker.start")
            }
            .buttonStyle(TrackerPressStyle())
            .modifier(commands.entersKeep ? PromptKey(shortcut: nil) : PromptKey.start)
        }
        .fixedSize()
    }

    private var awayPick: PromptAwayPick? { commands.model.goingAway(on: screen) }

    private var primary: Bool { commands.startIsPrimary }

    private var fill: Color { awayPick == nil ? Night.reason(screen.reason) : Night.sprout }

    private var startLabel: String {
        awayPick.map { Copywriter.activityPromptGoAway($0.label) } ?? screen.startLabel
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.promptButtonRadius, style: .continuous)
    }

    private var skipID: String {
        switch screen.skip {
        case .skip: "tracker.skip"
        case .close: "tracker.close"
        case .answerNo: "tracker.no"
        case .later: "tracker.later"
        }
    }
}
