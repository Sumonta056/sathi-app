import SathiCore
import SwiftUI

struct MonthGrid<Cell: View>: View {
    let leadingBlanks: Int
    let count: Int
    @ViewBuilder let cell: (Int) -> Cell

    var body: some View {
        LazyVGrid(columns: columns, spacing: UIMetrics.reportsMonthCellGap) {
            ForEach(Copywriter.reportsWeekdays.indices, id: \.self) { index in
                Text(verbatim: Copywriter.reportsWeekdays[index])
                    .font(Typography.tracker(UIMetrics.reportsWeekdayFont, .semibold))
                    .foregroundStyle(Night.faint)
            }
            ForEach(0 ..< leadingBlanks, id: \.self) { index in
                Color.clear.frame(height: 0).id("blank-\(index)")
            }
            ForEach(0 ..< count, id: \.self) { index in
                cell(index)
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: UIMetrics.reportsMonthCellGap), count: Copywriter.reportsWeekdays.count)
    }
}

struct MonthHeader<Trailing: View>: View {
    let title: String
    let canGoForward: Bool
    let step: (Int) -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: UIMetrics.reportsMonthGap) {
            arrow("chevron.left", label: Copywriter.reportsPreviousMonth, enabled: true) { step(-1) }
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.reportsCardTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
            arrow("chevron.right", label: Copywriter.reportsNextMonth, enabled: canGoForward) { step(1) }
        }
    }

    private func arrow(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.reportsTabRadius, style: .continuous)
        return Button(action: action) {
            Image(systemName: symbol)
                .font(Typography.badge)
                .foregroundStyle(enabled ? Night.chipText : Night.faint)
                .frame(width: UIMetrics.reportsMonthArrow, height: UIMetrics.reportsMonthArrow)
                .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
