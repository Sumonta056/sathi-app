import SathiCore
import SwiftUI

struct QuickActionRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: UIMetrics.quickActionSpacing) {
            action("plus", Copywriter.quickToolTitle, label: Copywriter.quickToolButton) { e.openQuickAdd() }
            if e.timeBlock == nil && e.calendarAccess != .denied {
                action("timer", Copywriter.blockCardTitle, label: Copywriter.blockStartButton) { e.openBlockStart() }
            }
            BreakMenu()
        }
    }

    private func action(_ symbol: String, _ title: String, label: String, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: UIMetrics.chipSpacing) {
                Image(systemName: symbol)
                    .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                    .accessibilityHidden(true)
                Text(verbatim: title).lineLimit(1)
            }
            .font(Typography.chip)
            .foregroundStyle(Night.text)
            .frame(maxWidth: .infinity)
            .frame(height: UIMetrics.quickActionHeight)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
