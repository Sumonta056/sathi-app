import SathiCore
import SwiftUI

struct ToolRow: View {
    @EnvironmentObject var e: Engine
    var body: some View {
        let quick = e.quickReminders.isEmpty
        let block = e.timeBlock == nil && e.calendarAccess != .denied
        if quick || block {
            HStack(spacing: UIMetrics.menuSpacing) {
                if quick { reminder }
                if block { timeBlock }
            }
        }
    }

    private var reminder: some View {
        Button { e.openQuickAdd() } label: {
            label("plus", Copywriter.quickToolTitle)
                .foregroundStyle(Night.quick)
                .overlay(
                    shape.strokeBorder(Night.quickBorder, style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: [UIMetrics.dashLength]))
                )
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copywriter.quickToolButton)
    }

    private var timeBlock: some View {
        Button { e.openBlockStart() } label: {
            label("timer", Copywriter.blockCardTitle)
                .foregroundStyle(Night.block)
                .background(shape.fill(Night.blockFill))
                .overlay(shape.strokeBorder(Night.blockBorder, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copywriter.blockStartButton)
    }

    private func label(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                .accessibilityHidden(true)
            Text(verbatim: title)
                .font(Typography.rowLabel)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIMetrics.toolButtonHeight)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
