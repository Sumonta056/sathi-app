import SathiCore
import SwiftUI

struct CalendarEventReadOnly: View {
    let form: CalendarEventForm
    let calendarName: String
    let calendar: Calendar
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarFieldSpacing) {
            Text(verbatim: form.title)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            Text(verbatim: when)
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
            if !calendarName.isEmpty {
                Text(verbatim: calendarName)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            }
            Text(verbatim: Copywriter.calendarEventReadOnly)
                .font(Typography.pill)
                .foregroundStyle(Night.faint)
            HStack {
                Spacer(minLength: 0)
                Button(action: open) { Text(verbatim: Copywriter.calendarOpenInCalendar) }
                    .buttonStyle(AccentButton(accent: Night.tracker, height: UIMetrics.calendarButtonHeight, text: Night.trackerOnAccent))
            }
        }
    }

    private var when: String {
        let day = CalendarPageDay.key(holding: form.start, calendar: calendar)
        return Copywriter.calendarEventDate(day, calendar: calendar) + " · " + Copywriter.trackerSpan(form.start, form.end, calendar: calendar)
    }
}
