import SwiftUI

struct OptionCard<Top: View>: View {
    let title: String
    let detail: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void
    @ViewBuilder let top: () -> Top

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                top()
                Text(verbatim: title)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                Text(verbatim: detail)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UIMetrics.optionPadding)
            .background(shape.fill(isSelected ? accent.opacity(UIMetrics.optionFillOpacity) : Night.card))
            .overlay(shape.strokeBorder(isSelected ? accent : Night.border, lineWidth: UIMetrics.chipBorder))
            .shadow(color: isSelected ? accent.opacity(UIMetrics.optionGlowOpacity) : .clear, radius: UIMetrics.optionGlowRadius)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.optionRadius, style: .continuous)
    }
}
