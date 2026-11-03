import SathiCore
import SwiftUI

struct BlockCalendarList: View {
    @EnvironmentObject var e: Engine
    @Binding var selection: String
    var idPrefix = "block.choice."

    var body: some View {
        VStack(spacing: UIMetrics.blockListSpacing) {
            ForEach(e.calendarChoices()) { row($0) }
        }
        .padding(UIMetrics.blockListPadding)
        .background(shape(UIMetrics.blockListRadius).fill(Night.bg))
        .overlay(shape(UIMetrics.blockListRadius).strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
    }

    private func row(_ c: CalendarChoice) -> some View {
        let on = c.id == selection
        return Button { selection = c.id } label: {
            HStack(spacing: UIMetrics.blockListRowSpacing) {
                CalendarDot(hex: c.colorHex, size: UIMetrics.blockListDot)
                Text(verbatim: c.title)
                    .font(Typography.chip)
                    .foregroundStyle(on ? Night.text : Night.chipText)
                HStack(spacing: UIMetrics.blockTextSpacing) {
                    Text(verbatim: "·")
                    Text(verbatim: c.account)
                }
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .accessibilityIdentifier(idPrefix + c.id)
            .padding(.horizontal, UIMetrics.blockListRowPadding)
            .frame(height: UIMetrics.blockListRowHeight)
            .background(shape(UIMetrics.blockListRowRadius).fill(on ? Night.navSelected : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
