import SathiCore
import SwiftUI

struct BlockDefaultCalendarList: View {
    @EnvironmentObject var e: Engine

    struct Group: Equatable {
        let account: String
        let calendars: [CalendarChoice]
    }

    var body: some View {
        let engine = e
        let selected = engine.startCalendarID
        VStack(alignment: .leading, spacing: UIMetrics.blockListSpacing) {
            ForEach(Self.groups(engine.calendarChoices()), id: \.account) { group in
                Text(verbatim: group.account)
                    .font(Typography.sectionLabel)
                    .foregroundStyle(Night.label)
                    .padding(UIMetrics.blockAccountPadding)
                ForEach(group.calendars) { row($0, on: $0.id == selected) }
            }
            Text(verbatim: Copywriter.blockSettingsCalendarNote)
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
                .fixedSize(horizontal: false, vertical: true)
                .padding(UIMetrics.blockAccountPadding)
        }
        .padding(UIMetrics.blockListRowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape(UIMetrics.blockListRadius).fill(Night.bg))
        .overlay(shape(UIMetrics.blockListRadius).strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
    }

    static func groups(_ choices: [CalendarChoice]) -> [Group] {
        var order: [String] = []
        var rows: [String: [CalendarChoice]] = [:]
        for c in choices {
            if rows[c.account] == nil { order.append(c.account) }
            rows[c.account, default: []].append(c)
        }
        return order.map { Group(account: $0, calendars: rows[$0] ?? []) }
    }

    private func row(_ c: CalendarChoice, on: Bool) -> some View {
        let engine = e
        return Button { engine.pickDefaultCalendar(c.id) } label: {
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
                        .foregroundStyle(Night.block)
                }
            }
            .padding(.horizontal, UIMetrics.blockListRowPadding)
            .frame(height: UIMetrics.blockSettingsRowHeight)
            .background(shape(UIMetrics.blockListRowRadius).fill(on ? Night.navSelected : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.block.calendar.\(c.id)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
