import SathiCore
import SwiftUI

struct CalendarShownList: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        CalendarSideCard(title: Copywriter.calendarShownTitle) {
            ForEach(e.shownCalendarGroups(), id: \.account) { group in
                VStack(alignment: .leading, spacing: UIMetrics.calendarSideRowSpacing) {
                    SectionLabel(group.account)
                    ForEach(group.calendars, id: \.choice.id) { row($0) }
                }
            }
        }
    }

    private func row(_ c: ShownCalendar) -> some View {
        Button { e.setCalendarShown(c.choice.id, !c.isShown) } label: {
            HStack(spacing: UIMetrics.calendarSideRowSpacing) {
                Image(systemName: c.isShown ? "checkmark.square.fill" : "square")
                    .font(.system(size: UIMetrics.calendarCheckSize, weight: .bold))
                    .foregroundStyle(c.isShown ? Color(hex: c.choice.colorHex) : Night.faint)
                Text(verbatim: c.choice.title)
                    .font(Typography.hint)
                    .foregroundStyle(c.isShown ? Night.text : Night.muted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar.shown." + c.choice.id)
        .accessibilityAddTraits(c.isShown ? .isSelected : [])
    }
}
