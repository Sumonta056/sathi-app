import SathiCore
import SwiftUI

struct CalendarEventPopover: View {
    @EnvironmentObject var e: Engine
    @State var form: CalendarEventForm
    @State var failure: String?
    let onClose: () -> Void

    init(form: CalendarEventForm, failure: String? = nil, onClose: @escaping () -> Void) {
        _form = State(initialValue: form)
        _failure = State(initialValue: failure)
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarPopoverSpacing) {
            Text(verbatim: heading)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            if form.readOnly {
                CalendarEventReadOnly(form: form, calendarName: calendarName, calendar: calendar) {
                    if let id = form.eventID { e.openEventInCalendar(id) }
                    onClose()
                }
            } else {
                editor
            }
        }
        .padding(UIMetrics.calendarPopoverPadding)
        .frame(width: UIMetrics.calendarPopoverWidth, alignment: .leading)
        .background(Night.card)
    }

    var calendar: Calendar { e.rangeCalendar }

    private var heading: String {
        if form.readOnly { return Copywriter.calendarEventHeading }
        return form.eventID == nil ? Copywriter.calendarNewEvent : Copywriter.calendarEditEvent
    }

    private var calendarName: String {
        e.shownCalendarGroups().flatMap(\.calendars).first { $0.choice.id == form.calendarID }?.choice.title ?? ""
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarPopoverSpacing) {
            titleField
            timeRow
            CalendarEventChoices(calendars: e.calendarPageWritableCalendars, selection: $form.calendarID)
            Text(verbatim: Copywriter.calendarEventHint)
                .font(Typography.pill)
                .foregroundStyle(Night.faint)
            if let failure {
                Text(verbatim: failure)
                    .font(Typography.hint)
                    .foregroundStyle(Night.tracker)
            }
            buttons
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarFieldSpacing) {
            SectionLabel(Copywriter.calendarEventTitle)
            LazyTextField(placeholder: Copywriter.calendarEventTitle, text: $form.title, startsEditing: form.eventID == nil, onSubmit: save)
                .modifier(QuickTextLimit(text: $form.title, limit: Limits.blockTitleMax))
                .frame(height: UIMetrics.calendarFieldHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.calendarFieldBorder)
                )
        }
    }

    private var timeRow: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarFieldSpacing) {
            SectionLabel(Copywriter.calendarEventTime)
            HStack(spacing: UIMetrics.calendarTimeRowSpacing) {
                Text(verbatim: Copywriter.calendarEventDate(CalendarPageDay.key(holding: form.start, calendar: calendar), calendar: calendar))
                    .font(Typography.chip)
                    .foregroundStyle(Night.chipText)
                    .padding(UIMetrics.calendarDateChipPadding)
                    .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
                TimeMenu(minutes: minutes(\.start), accent: Night.tracker)
                Text(verbatim: Copywriter.calendarEventTo)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                TimeMenu(minutes: minutes(\.end), accent: Night.tracker)
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            if form.eventID != nil {
                Button(action: delete) { Text(verbatim: Copywriter.calendarEventDelete) }
                    .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.calendarButtonHeight, border: Night.border))
            }
            Spacer(minLength: 0)
            Button(action: onClose) { Text(verbatim: Copywriter.calendarEventCancel) }
                .buttonStyle(GhostButton(accent: Night.chipText, height: UIMetrics.calendarButtonHeight, border: Night.border))
            Button(action: save) { Text(verbatim: Copywriter.calendarEventSave) }
                .buttonStyle(AccentButton(accent: Night.tracker, height: UIMetrics.calendarButtonHeight, text: Night.trackerOnAccent))
                .disabled(!form.canSave)
        }
    }

    private func minutes(_ edge: KeyPath<CalendarEventForm, Date>) -> Binding<Int> {
        let clock = DayClock(calendar: calendar)
        return Binding(
            get: { clock.minutesOfDay(form[keyPath: edge]) },
            set: { picked in
                let start = edge == \.start ? picked : clock.minutesOfDay(form.start)
                let end = edge == \.end ? picked : clock.minutesOfDay(form.end)
                form = form.withTimes(startMinutes: start, endMinutes: end, calendar: calendar)
            }
        )
    }
}
