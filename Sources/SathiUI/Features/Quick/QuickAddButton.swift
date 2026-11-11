import SathiCore
import SwiftUI

struct QuickAddButton: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Button { e.openQuickAdd() } label: {
            HStack(spacing: UIMetrics.quickTimeSpacing) {
                Image(systemName: "plus")
                    .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                Text(verbatim: "Quick reminder")
                    .font(Typography.rowLabel)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Night.quick)
            .padding(.horizontal, UIMetrics.chipPadding)
            .frame(height: UIMetrics.quickAddHeight)
            .overlay(
                RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                    .strokeBorder(Night.quickBorder, style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: [UIMetrics.dashLength]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, UIMetrics.quickCardSpacing)
    }
}
