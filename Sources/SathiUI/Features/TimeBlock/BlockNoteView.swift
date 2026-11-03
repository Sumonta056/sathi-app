import SathiCore
import SwiftUI

struct BlockNoteView: View {
    let note: BlockNote

    var body: some View {
        content
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.bubbleBorder))
            .padding(UIMetrics.bubbleShadowPadding)
            .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var content: some View {
        switch note {
        case let .savedPrevious(minutes, title, calendarTitle):
            toast("checkmark", Night.block, Copywriter.blockSavedPrevious(minutes: minutes, title: title, calendar: calendarTitle))
        case .tooShort:
            toast("exclamationmark.circle", Night.muted, Copywriter.blockTooShort)
        }
    }

    private func toast(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: UIMetrics.blockToastSpacing) {
            Image(systemName: icon)
                .font(.system(size: UIMetrics.blockToastIcon, weight: .semibold))
                .foregroundStyle(tint)
            Text(verbatim: text)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
        }
        .padding(UIMetrics.blockToastPadding)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.blockNoteRadius, style: .continuous)
    }
}
