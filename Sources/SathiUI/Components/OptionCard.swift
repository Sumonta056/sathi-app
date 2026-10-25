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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

struct OptionCardRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.chipSpacing) {
            content()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
