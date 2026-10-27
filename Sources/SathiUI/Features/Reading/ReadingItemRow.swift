import SathiCore
import SwiftUI

struct ReadingItemRow: View {
    enum Position {
        case unread(index: Int, count: Int)
        case read
    }

    @EnvironmentObject var e: Engine
    let item: ReadingItem
    let position: Position

    var body: some View {
        HStack(spacing: UIMetrics.readingRowSpacing) {
            VStack(alignment: .leading, spacing: UIMetrics.readingTextSpacing) {
                HStack(spacing: UIMetrics.readingTagSpacing) {
                    Text(verbatim: item.displayTitle)
                        .font(Typography.rowLabel)
                        .foregroundStyle(isRead ? Night.muted : Night.text)
                        .lineLimit(1)
                    if isFirst { upNext }
                }
                Text(verbatim: subtitle)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            controls
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
        }
    }

    @ViewBuilder private var controls: some View {
        switch position {
        case let .unread(index, count):
            if index > 0 {
                iconButton("chevron.up", Copywriter.readingMoveUp(item.displayTitle)) { move(to: index - 1) }
            } else {
                slot
            }
            if index < count - 1 {
                iconButton("chevron.down", Copywriter.readingMoveDown(item.displayTitle)) { move(to: index + 1) }
            } else {
                slot
            }
        case .read:
            Button { e.undoReadingDone(id: item.id) } label: {
                Text(verbatim: Copywriter.readingUndo)
            }
            .buttonStyle(GhostButton(accent: Night.reading, height: UIMetrics.chipHeight))
            .disabled(!e.canUndoReading)
            .accessibilityLabel(Text(verbatim: Copywriter.readingUndoLabel(item.displayTitle)))
        }
        iconButton("xmark", Copywriter.readingRemove(item.displayTitle)) { e.removeReading(id: item.id) }
    }

    private var upNext: some View {
        Text(verbatim: Copywriter.readingUpNext)
            .font(Typography.badge)
            .foregroundStyle(Night.onAccent)
            .padding(UIMetrics.badgePadding)
            .background(Capsule().fill(Night.reading))
    }

    private var isRead: Bool {
        if case .read = position { true } else { false }
    }

    private var isFirst: Bool {
        if case .unread(0, _) = position { true } else { false }
    }

    private var subtitle: String {
        if let day = item.doneOn { return Copywriter.readingReadOn(day) }
        guard item.title.isEmpty else { return item.source }
        let link = item.url.absoluteString
        guard let scheme = item.url.scheme else { return link }
        return link.replacingOccurrences(of: scheme + "://", with: "", options: .anchored)
    }

    private var slot: some View {
        Color.clear.frame(width: UIMetrics.readingIconButton, height: UIMetrics.readingIconButton)
    }

    private func move(to index: Int) {
        e.moveReading(id: item.id, to: index)
    }

    private func iconButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.readingIconSize, weight: .heavy))
                .foregroundStyle(Night.reading)
                .frame(width: UIMetrics.readingIconButton, height: UIMetrics.readingIconButton)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}
