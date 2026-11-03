import SathiCore
import SwiftUI

struct BlockNoteView: View {
    @EnvironmentObject var e: Engine
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
        case let .started(title, length, end, calendarTitle):
            started(title: title, detail: Copywriter.blockStartedDetail(
                length: length, end: end, calendarTitle: calendarTitle, calendar: Calendar.gregorian(in: e.timeZone)
            ))
        case let .savedPrevious(minutes, title, calendarTitle):
            toast("checkmark", Night.block, Copywriter.blockSavedPrevious(minutes: minutes, title: title, calendar: calendarTitle))
        case .tooShort:
            toast("exclamationmark.circle", Night.muted, Copywriter.blockTooShort)
        }
    }

    private func started(title: String, detail: String) -> some View {
        HStack(spacing: UIMetrics.blockNoteSpacing) {
            BlockRing(progress: 0, size: UIMetrics.blockNoteRing, line: UIMetrics.blockNoteRingLine)
            VStack(alignment: .leading, spacing: UIMetrics.blockNoteTextSpacing) {
                Text(verbatim: Copywriter.blockStartedTitle(title))
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                Text(verbatim: detail)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            Button { e.undoStartedNote(note) } label: {
                Text(verbatim: Copywriter.blockUndo).accessibilityIdentifier("block.undo")
            }
            .buttonStyle(GhostButton(accent: Night.text, height: UIMetrics.blockUndoHeight))
        }
        .padding(UIMetrics.blockNotePadding)
        .frame(width: UIMetrics.blockNoteWidth)
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
