import SathiCore
import SwiftUI

struct PromptRunningCard: View {
    let card: PromptCard
    let screen: ActivityPromptScreen
    let state: TrackerPromptState
    let commands: PromptCommands

    private var color: Color { Night.reason(screen.reason) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptRunRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.promptRunGap) {
            tagLine
            HStack(spacing: UIMetrics.promptRunKeepGap) {
                VStack(alignment: .leading, spacing: UIMetrics.promptRunNameGap) {
                    Text(verbatim: card.text)
                        .font(Typography.tracker(UIMetrics.promptRunNameFont, .heavy))
                        .foregroundStyle(Night.text)
                        .lineLimit(1)
                    detailLine
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let label = screen.keepLabel, commands.model.goingAway(on: screen) == nil { keepButton(label) }
            }
            if let progress = card.progress { bar(progress) }
        }
        .padding(UIMetrics.promptRunPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(color.opacity(UIMetrics.promptRunFill)))
        .overlay(shape.strokeBorder(color, lineWidth: UIMetrics.promptRunBorder))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("prompt.card")
    }

    private var tagLine: some View {
        HStack(spacing: UIMetrics.promptTagGap) {
            Circle().fill(color).frame(width: UIMetrics.promptBoxDot, height: UIMetrics.promptBoxDot)
            Text(verbatim: card.tag)
                .font(Typography.tracker(UIMetrics.promptTagFont, .heavy))
                .tracking(UIMetrics.promptTagTracking)
                .foregroundStyle(color)
        }
    }

    private var detailLine: some View {
        HStack(spacing: UIMetrics.promptRunLineGap) {
            if let category = card.category {
                HStack(spacing: UIMetrics.promptBoxGap) {
                    if let hex = state.categories.first(where: { $0.name == category })?.colorHex {
                        Circle().fill(Color(hex: hex)).frame(width: UIMetrics.promptBoxDot, height: UIMetrics.promptBoxDot)
                    }
                    Text(verbatim: category)
                }
            }
            if !card.detail.isEmpty { Text(verbatim: card.detail) }
        }
        .lineLimit(1)
        .font(Typography.tracker(UIMetrics.promptRunDetailFont, .semibold))
        .foregroundStyle(Night.chipText)
    }

    private func bar(_ progress: Double) -> some View {
        let shape = Capsule()
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                shape.fill(color.opacity(UIMetrics.promptRunTrack))
                shape.fill(color).frame(width: geo.size.width * progress)
            }
        }
        .frame(height: UIMetrics.promptRunBar)
        .accessibilityHidden(true)
    }

    private func keepButton(_ label: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptButtonRadius, style: .continuous)
        return Button(action: commands.keep) {
            Text(verbatim: label)
                .font(Typography.tracker(UIMetrics.promptStartFont, .heavy))
                .foregroundStyle(Night.onAccent)
                .lineLimit(1)
                .padding(.horizontal, UIMetrics.promptStartPadding)
                .frame(height: UIMetrics.promptButtonHeight)
                .background(shape.fill(color))
                .contentShape(shape)
                .accessibilityIdentifier("prompt.keep")
        }
        .buttonStyle(TrackerPressStyle())
        .fixedSize()
        .modifier(commands.entersKeep ? PromptKey.start : PromptKey(shortcut: nil))
    }
}

struct PromptOrSwitch: View {
    var body: some View {
        HStack(spacing: UIMetrics.promptOrGap) {
            Night.promptCardLine.frame(height: UIMetrics.promptBorder)
            Text(verbatim: Copywriter.activityPromptOrSwitch)
                .font(Typography.tracker(UIMetrics.promptNoteFont, .semibold))
                .foregroundStyle(Night.promptSecondary)
                .fixedSize()
            Night.promptCardLine.frame(height: UIMetrics.promptBorder)
        }
    }
}
