import SathiCore
import SwiftUI

struct ActivityLogView: View {
    let day: ActivityDay
    let categories: [ActivityCategory]
    let calendar: Calendar
    let actions: ActivityDayActions
    @State private var editing: String?
    @State private var adding: AddTarget?

    enum AddTarget: Equatable {
        case gap(DateInterval)
        case past
    }

    var body: some View {
        let dayStart = day.day.start(in: calendar)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ActivityLogRows.make(day)) { row in
                if case let .activity(a, _) = row, editing == row.id {
                    ActivityEditForm(
                        draft: ActivityEditDraft(a, calendar: calendar), categories: categories, dayStart: dayStart,
                        calendar: calendar, save: { actions.edit(a.id, $0) },
                        delete: { actions.delete(a.id); editing = nil }, close: { editing = nil }
                    )
                } else if case let .gap(interval) = row, adding == .gap(interval) {
                    form(interval, dayStart)
                } else {
                    ActivityLogRowView(
                        row: row, categories: categories, calendar: calendar,
                        onEdit: { editing = row.id }, onFill: { adding = .gap($0) }, onSaveToCalendar: actions.saveToCalendar
                    )
                }
                Divider().overlay(Night.divider)
            }
            if day.activities.isEmpty { Text(verbatim: Copywriter.trackerNoActivities).font(Typography.hint).foregroundStyle(Night.muted) }
            addPast(dayStart)
        }
    }

    @ViewBuilder
    private func addPast(_ dayStart: Date) -> some View {
        if adding == .past {
            form(DateInterval(start: day.hours.start, duration: 0), dayStart)
        } else {
            Button(Copywriter.trackerAddPast) { adding = .past }
                .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
                .padding(.top, UIMetrics.sectionSpacing)
        }
    }

    private func form(_ interval: DateInterval, _ dayStart: Date) -> some View {
        let end = interval.duration > 0 ? interval.end : interval.start
            .addingTimeInterval(TimeInterval(Limits.trackerUsualLengthDefault) * Timing.minute)
        return ActivityEditForm(
            draft: ActivityEditDraft(start: interval.start, end: end, calendar: calendar), categories: categories,
            dayStart: dayStart, calendar: calendar, save: { actions.add($0) }, delete: nil, close: { adding = nil }
        )
    }
}
