import SathiCore
import SwiftUI

struct TrackerCalendarList: View {
    let choices: [CalendarChoice]
    let isOn: (String) -> Bool
    let onTap: (String) -> Void
    let identifier: String

    static let emptyText = "No calendars found on this Mac."

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.blockListSpacing) {
            if choices.isEmpty {
                Text(verbatim: Self.emptyText)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .padding(UIMetrics.blockListRowPadding)
            }
            ForEach(BlockDefaultCalendarList.groups(choices), id: \.account) { group in
                Text(verbatim: group.account)
                    .font(Typography.sectionLabel)
                    .foregroundStyle(Night.label)
                    .padding(UIMetrics.blockListRowPadding)
                ForEach(group.calendars) { row($0) }
            }
        }
        .padding(UIMetrics.blockListRowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape(UIMetrics.blockListRadius).fill(Night.bg))
        .overlay(shape(UIMetrics.blockListRadius).strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
    }

    private func row(_ c: CalendarChoice) -> some View {
        let on = isOn(c.id)
        return Button { onTap(c.id) } label: {
            HStack(spacing: UIMetrics.blockListRowSpacing) {
                CalendarDot(hex: c.colorHex, size: UIMetrics.blockListDot)
                Text(verbatim: c.title)
                    .font(Typography.chip)
                    .foregroundStyle(on ? Night.text : Night.chipText)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: UIMetrics.blockStatusIcon, weight: .heavy))
                        .foregroundStyle(Night.tracker)
                }
            }
            .padding(.horizontal, UIMetrics.blockListRowPadding)
            .frame(height: UIMetrics.blockSettingsRowHeight)
            .background(shape(UIMetrics.blockListRowRadius).fill(on ? Night.navSelected : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(identifier).\(c.id)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
