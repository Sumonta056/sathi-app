import SathiCore
import SwiftUI

struct TodoListSwatches: View {
    @Binding var selection: String

    private var rows: [[Int]] {
        let all = Array(Limits.todoListColors.indices)
        return stride(from: 0, to: all.count, by: UIMetrics.todoSwatchColumns).map {
            Array(all[$0 ..< min($0 + UIMetrics.todoSwatchColumns, all.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoChipSpacing) {
            SectionLabel(Copywriter.todoListColor)
            VStack(alignment: .leading, spacing: UIMetrics.todoTileGap) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: UIMetrics.todoTileGap) {
                        ForEach(row, id: \.self) { swatch($0) }
                    }
                }
            }
        }
    }

    private func swatch(_ i: Int) -> some View {
        let hex = Limits.todoListColors[i]
        let on = hex == selection
        return Button { selection = hex } label: {
            Circle()
                .fill(Night.todoList(hex))
                .overlay { if on { Circle().strokeBorder(Night.text, lineWidth: UIMetrics.todoSwatchRing) } }
                .frame(width: UIMetrics.todoSwatch, height: UIMetrics.todoSwatch)
                .contentShape(Circle())
                .accessibilityIdentifier("todos.listform.color.\(i)")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: hex))
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
