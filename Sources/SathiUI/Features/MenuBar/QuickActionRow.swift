import SathiCore
import SwiftUI

struct QuickActionRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(spacing: UIMetrics.quickActionSpacing) {
            HStack(spacing: UIMetrics.quickActionSpacing) {
                action("plus", Copywriter.quickPanelReminder, label: Copywriter.quickToolButton, id: "quick.reminder") {
                    e.openQuickAdd()
                }
                BreakMenu().accessibilityIdentifier("quick.break")
            }
            if e.timeBlock == nil && e.calendarAccess != .denied {
                action("timer", Copywriter.blockCardTitle, label: Copywriter.blockStartButton, id: "quick.timeBlock") {
                    e.openBlockStart()
                }
            }
        }
    }

    private func action(_ symbol: String, _ title: String, label: String, id: String, tap: @escaping () -> Void) -> some View {
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
        .accessibilityIdentifier(id)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
