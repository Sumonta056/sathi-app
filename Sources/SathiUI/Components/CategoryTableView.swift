import SathiCore
import SwiftUI

struct CategoryTableView: View {
    let table: CategoryTable
    let summary: String
    var columns = 1
    var showsChange = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.categoryTableHeaderGap) {
                Text(verbatim: table.totalText)
                    .font(.system(size: UIMetrics.categoryTableTotalFont, weight: .black, design: .rounded))
                    .foregroundStyle(Night.text)
                Text(verbatim: summary)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            CategoryTableBar(rows: table.rows)
            HStack(alignment: .top, spacing: UIMetrics.categoryTableColumnGap) {
                ForEach(Array(Self.split(table.rows, columns: columns).enumerated()), id: \.offset) { _, rows in
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            CategoryTableRowView(row: row, showsChange: showsChange, showsDivider: index < rows.count - 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
    }

    static func split(_ rows: [CategoryTableRow], columns: Int) -> [[CategoryTableRow]] {
        let count = max(1, columns)
        let size = max(1, (rows.count + count - 1) / count)
        return stride(from: 0, to: rows.count, by: size).map { Array(rows[$0 ..< min($0 + size, rows.count)]) }
    }
}
