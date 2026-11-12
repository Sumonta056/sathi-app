import SathiCore
import SwiftUI

struct PillSegment<Option: Hashable>: View {
    let options: [Option]
    @Binding var selected: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let on = option == selected
                Button { selected = option } label: {
                    Text(verbatim: title(option))
                        .font(Typography.chip)
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(on ? Night.text : Night.muted)
                        .padding(UIMetrics.rangeSegmentPadding)
                        .background(Capsule().fill(on ? Night.navSelected : .clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(UIMetrics.rangeSegmentInset)
        .background(Capsule().fill(Night.card))
        .overlay(Pill().strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }
}
