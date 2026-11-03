import SathiCore
import SwiftUI

struct LengthChips: View {
    @Binding var selection: TimeBlockLength

    private static let choices = TimeBlockLength.choices.map { ($0, Copywriter.blockChipLabel($0)) }

    var body: some View {
        HStack(spacing: UIMetrics.blockChipSpacing) {
            ForEach(Self.choices, id: \.1) { length, label in
                chip(length, label)
            }
        }
    }

    private func chip(_ length: TimeBlockLength, _ label: String) -> some View {
        let on = selection == length
        let shape = RoundedRectangle(cornerRadius: UIMetrics.blockChipRadius, style: .continuous)
        return Button { selection = length } label: {
            Text(verbatim: label)
                .font(Typography.pill)
                .foregroundStyle(on ? Night.onAccent : Night.chipText)
                .frame(maxWidth: .infinity, minHeight: UIMetrics.blockChipHeight)
                .background(shape.fill(on ? Night.block : Color.clear))
                .overlay(shape.strokeBorder(on ? Night.block : Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
                .accessibilityIdentifier("block.chip." + label)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
