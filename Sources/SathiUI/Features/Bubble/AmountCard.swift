import SwiftUI

struct AmountCard: View {
    let amount: Double
    let label: String
    var level: Double?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: UIMetrics.chipSpacing) {
                GlassIcon(fill: level ?? amount, ink: .night)
                    .frame(width: UIMetrics.amountGlassSize.width, height: UIMetrics.amountGlassSize.height)
                Text(label)
                    .font(Typography.amountLabel)
                    .foregroundStyle(Night.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIMetrics.amountCardHeight)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(hovering ? Night.water : Night.border, lineWidth: UIMetrics.chipBorder))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.amountCardRadius, style: .continuous)
    }
}
