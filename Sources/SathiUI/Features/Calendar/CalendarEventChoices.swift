import SathiCore
import SwiftUI

struct CalendarEventChoices: View {
    let calendars: [CalendarChoice]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarFieldSpacing) {
            SectionLabel(Copywriter.calendarEventCalendar)
            TrackerFlowLayout(spacing: UIMetrics.calendarChoiceSpacing) {
                ForEach(calendars) { chip($0) }
            }
        }
    }

    private func chip(_ c: CalendarChoice) -> some View {
        let on = c.id == selection
        let shape = RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
        return Button { selection = c.id } label: {
            HStack(spacing: UIMetrics.calendarChoiceSpacing) {
                CalendarDot(hex: c.colorHex, size: UIMetrics.calendarChoiceDot)
                Text(verbatim: c.title)
                    .font(Typography.chip)
                    .foregroundStyle(on ? Night.onAccent : Night.chipText)
                    .lineLimit(1)
            }
            .padding(UIMetrics.calendarChoicePadding)
            .background(shape.fill(on ? Night.sprout : Night.bg))
            .overlay(shape.strokeBorder(on ? Night.sprout : Night.fieldBorder, lineWidth: UIMetrics.chipBorder))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar.event.choice." + c.id)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
