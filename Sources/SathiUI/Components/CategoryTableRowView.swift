import SathiCore
import SwiftUI

struct CategoryTableRowView: View {
    let row: CategoryTableRow
    let showsChange: Bool
    let showsDivider: Bool

    var body: some View {
        HStack(spacing: UIMetrics.categoryTableRowGap) {
            RoundedRectangle(cornerRadius: UIMetrics.categoryTableSquareRadius, style: .continuous)
                .fill(Night.category(row.colorHex))
                .frame(width: UIMetrics.categoryTableSquare, height: UIMetrics.categoryTableSquare)
            Text(verbatim: row.name)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: row.hoursText)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .frame(width: UIMetrics.categoryTableHoursWidth, alignment: .trailing)
            Text(verbatim: row.percentText)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .lineLimit(1)
                .frame(width: UIMetrics.categoryTablePercentWidth, alignment: .trailing)
            if showsChange {
                RangeChangeText(change: row.change, text: row.changeText)
                    .lineLimit(1)
                    .frame(width: UIMetrics.categoryTableChangeWidth, alignment: .trailing)
            }
        }
        .padding(.vertical, UIMetrics.categoryTableRowPadding)
        .overlay(alignment: .bottom) {
            if showsDivider { Rectangle().fill(Night.divider).frame(height: UIMetrics.cardBorder) }
        }
    }
}
