import SwiftUI

struct ChipRow<Value: Hashable>: View {
    let options: [Value]
    let accent: Color
    let isSelected: (Value) -> Bool
    let onTap: (Value) -> Void
    let label: (Value) -> String
    var spokenLabel: ((Value) -> String)?
    var chipWidth: CGFloat?

    var body: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            ForEach(options, id: \.self) { chip($0) }
        }
    }

    private func chip(_ value: Value) -> some View {
        let on = isSelected(value)
        return Button { onTap(value) } label: {
            Text(verbatim: label(value))
                .font(Typography.chip)
                .foregroundStyle(on ? accent : Night.chipText)
                .padding(.horizontal, UIMetrics.chipPadding)
                .frame(minWidth: chipWidth)
                .frame(height: UIMetrics.chipHeight)
                .background(Pill().fill(on ? accent.opacity(UIMetrics.chipFillOpacity) : .clear))
                .overlay(Pill().strokeBorder(on ? accent : Night.fieldBorder, lineWidth: UIMetrics.chipBorder))
                .contentShape(Pill())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(Text(verbatim: spokenLabel?(value) ?? label(value)))
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
