import SathiCore
import SwiftUI

struct TodoSmartTiles: View {
    @Binding var selection: TodoSelection
    @EnvironmentObject var e: Engine

    private let rows: [[TodoSmartList]] = [[.today, .scheduled], [.all, .completed]]

    var body: some View {
        VStack(spacing: UIMetrics.todoTileGap) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: UIMetrics.todoTileGap) {
                    ForEach(row, id: \.self) { tile($0) }
                }
            }
        }
    }

    private func tile(_ list: TodoSmartList) -> some View {
        let look = Night.todoTile(list)
        let on = selection == .smart(list)
        return Button { selection = .smart(list) } label: {
            VStack(alignment: .leading, spacing: UIMetrics.todoTileSpacing) {
                HStack {
                    Circle().fill(look.dot).frame(width: UIMetrics.todoTileDot, height: UIMetrics.todoTileDot)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(e.todoCount(.smart(list)))")
                        .font(Typography.tracker(UIMetrics.todoTileCountFont, .heavy))
                }
                Text(verbatim: Copywriter.todoSmartListName(list))
                    .font(Typography.tracker(UIMetrics.todoTileLabelFont, .semibold))
            }
            .foregroundStyle(Night.text)
            .padding(UIMetrics.todoTilePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(look.fill))
            .overlay { if on { shape.strokeBorder(look.dot, lineWidth: UIMetrics.todoBorder) } }
            .contentShape(shape)
            .accessibilityIdentifier("todos.tile.\(list.rawValue)")
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoTileRadius, style: .continuous)
    }
}
