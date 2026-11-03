import SathiCore
import SwiftUI

struct BlockWidgetAction: View {
    @EnvironmentObject var e: Engine
    let block: TimeBlock
    let showsUndo: Bool

    var body: some View {
        if showsUndo { undoButton } else { endButton }
    }

    private var undoButton: some View {
        Button { e.undoBlockStart(block.id) } label: {
            Text(verbatim: Copywriter.blockUndo).accessibilityIdentifier("block.widget.undo")
        }
        .buttonStyle(GhostButton(accent: Night.text, height: UIMetrics.blockUndoHeight))
        .fixedSize()
    }

    private var endButton: some View {
        Button { e.endBlock() } label: {
            Image(systemName: "xmark")
                .font(.system(size: UIMetrics.blockWidgetEndIcon, weight: .heavy))
                .foregroundStyle(Night.chipText)
                .frame(width: UIMetrics.blockWidgetEnd, height: UIMetrics.blockWidgetEnd)
                .background(Circle().fill(Night.bg))
                .contentShape(Circle())
                .accessibilityIdentifier("block.widget.end")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copywriter.blockEndAndSave)
        .help(Copywriter.blockEndAndSave)
    }
}
