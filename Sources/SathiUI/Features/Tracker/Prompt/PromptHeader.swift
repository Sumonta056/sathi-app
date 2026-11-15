import SathiCore
import SwiftUI

struct PromptHeader: View {
    let screen: ActivityPromptScreen
    let state: TrackerPromptState
    let model: ActivityPromptModel
    let onSkip: () -> Void
    var onDrop: () -> Bool = { true }

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.promptHeaderGap) {
            tile
            VStack(alignment: .leading, spacing: UIMetrics.promptHeaderLines) {
                tagLine
                Text(verbatim: screen.title)
                    .font(Typography.tracker(UIMetrics.promptTitleFont, .heavy))
                    .foregroundStyle(Night.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: screen.message)
                    .font(Typography.tracker(UIMetrics.promptMessageFont, .medium))
                    .foregroundStyle(Night.chipText)
                    .fixedSize(horizontal: false, vertical: true)
                if screen.showsWhere { PromptWhereBoxes(state: state, form: model.places, showsIWasHere: screen.showsIWasHere) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            close
        }
        .padding(UIMetrics.promptHeaderPadding)
        .background(PromptDragHandle(onDrop: onDrop))
        .background(Night.promptHeader)
        .overlay(alignment: .top) { color.frame(height: UIMetrics.promptTopBar) }
    }

    private var color: Color { Night.reason(screen.reason) }

    private var tile: some View {
        Image(systemName: Self.icon(screen.reason))
            .font(.system(size: UIMetrics.promptTileIcon, weight: .semibold))
            .foregroundStyle(Night.onAccent)
            .frame(width: UIMetrics.promptTile, height: UIMetrics.promptTile)
            .background(RoundedRectangle(cornerRadius: UIMetrics.promptTileRadius, style: .continuous).fill(color))
            .accessibilityHidden(true)
    }

    private var tagLine: some View {
        HStack(spacing: UIMetrics.promptTagGap) {
            Text(verbatim: screen.tag)
                .font(Typography.tracker(UIMetrics.promptTagFont, .heavy))
                .tracking(UIMetrics.promptTagTracking)
                .foregroundStyle(Night.onAccent)
                .padding(UIMetrics.promptTagPadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous).fill(color))
            Text(verbatim: screen.timeText)
                .font(.system(size: UIMetrics.promptTimeFont, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    private var close: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptCloseRadius, style: .continuous)
        return Button(action: onSkip) {
            Image(systemName: "xmark")
                .font(.system(size: UIMetrics.promptButtonFont, weight: .semibold))
                .foregroundStyle(Night.chipText)
                .frame(width: UIMetrics.promptClose, height: UIMetrics.promptClose)
                .overlay(shape.strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
                .contentShape(shape)
                .accessibilityIdentifier("prompt.dismiss")
        }
        .buttonStyle(TrackerPressStyle())
        .accessibilityLabel(Text(verbatim: Copywriter.trackerSkip))
    }

    static func icon(_ reason: PromptReason) -> String {
        switch reason {
        case .ask: "clock"
        case .shortcut: "keyboard"
        case .ends: "flag"
        case .back: "door.left.hand.open"
        case .event: "calendar"
        }
    }
}
