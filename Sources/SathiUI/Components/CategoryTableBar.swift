import SathiCore
import SwiftUI

struct CategoryTableBar: View {
    let rows: [CategoryTableRow]

    var body: some View {
        GeometryReader { g in
            HStack(spacing: UIMetrics.categoryTableSegmentGap) {
                ForEach(rows) { row in
                    Rectangle()
                        .fill(Night.category(row.colorHex))
                        .frame(width: width(row, in: g.size.width))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: UIMetrics.categoryTableBarHeight)
        .background(Night.divider)
        .clipShape(RoundedRectangle(cornerRadius: UIMetrics.categoryTableBarRadius, style: .continuous))
    }

    private func width(_ row: CategoryTableRow, in available: CGFloat) -> CGFloat {
        let total = rows.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return 0 }
        let gaps = CGFloat(max(0, rows.count - 1)) * UIMetrics.categoryTableSegmentGap
        return max(0, available - gaps) * CGFloat(row.seconds / total)
    }
}
