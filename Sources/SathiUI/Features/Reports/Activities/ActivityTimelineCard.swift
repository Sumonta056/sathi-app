import SathiCore
import SwiftUI

struct ActivityTimelineCard: View {
    let day: ActivityDay
    let categories: [ActivityCategory]
    let calendar: Calendar
    var calendars: [CalendarChoice] = []
    var actions = ActivityDayActions()
    @State var editing: ActivityEditTarget?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesTileRadius, style: .continuous)
        let rows = ActivityLogRows.make(day)
        VStack(alignment: .leading, spacing: UIMetrics.activitiesCardGap) {
            header(rows)
            ActivityRibbon(
                segments: ActivityTimeline.segments(day), hours: day.hours, categories: categories,
                height: UIMetrics.activitiesLaneHeight, radius: UIMetrics.activitiesLaneRadius, showsLabels: false
            )
            ActivityAxis(hours: day.hours, calendar: calendar)
            HStack(alignment: .top, spacing: UIMetrics.activitiesGap) {
                ActivityTimelineList(
                    rows: rows, categories: categories, calendar: calendar,
                    calendarNames: Dictionary(calendars.map { ($0.id, $0.title) }, uniquingKeysWith: { a, _ in a }),
                    editing: editing, onEdit: { editing = .activity($0) }, onFill: { editing = .add($0) }, onDelete: actions.delete
                )
                if let editing, let section = section(editing) {
                    section
                        .frame(width: UIMetrics.activitiesEditWidth)
                        .id(editing.key)
                }
            }
        }
        .padding(UIMetrics.activitiesCardPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func header(_ rows: [ActivityLogRow]) -> some View {
        HStack(spacing: UIMetrics.activitiesColumnGap) {
            Text(verbatim: Copywriter.activitiesTimeline)
                .font(Typography.tracker(UIMetrics.activitiesTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: Copywriter.activitiesCountLine(
                ActivityDayStats(day).count,
                gaps: rows.filter { !ActivityTimelineList.isActivity($0) }.count
            ))
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            Button(Copywriter.activitiesAdd) { editing = .add(newSpan) }
                .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.activitiesHeaderButton))
        }
    }

    private var newSpan: DateInterval {
        let length = TimeInterval(Limits.trackerUsualLengthDefault) * Timing.minute
        return DateInterval(start: day.hours.start, duration: length)
    }

    private func section(_ target: ActivityEditTarget) -> ActivityEditSection? {
        let dayStart = day.day.start(in: calendar)
        switch target {
        case let .activity(id):
            guard let a = day.activities.first(where: { $0.id == id }) else { return nil }
            return ActivityEditSection(
                draft: ActivityEditDraft(a, calendar: calendar), title: Copywriter.activitiesEditTitle,
                accent: a.kind == .away ? Night.chipText : ActivityColors.color(a.category, in: categories),
                categories: categories, calendars: calendars, dayStart: dayStart, calendar: calendar,
                save: { actions.edit(id, $0) }, delete: { actions.delete(id); editing = nil }, close: { editing = nil }
            )
        case let .add(span):
            return ActivityEditSection(
                draft: ActivityEditDraft(start: span.start, end: span.end, calendar: calendar), title: Copywriter.activitiesAddTitle,
                accent: Night.tracker, categories: categories, calendars: calendars, dayStart: dayStart, calendar: calendar,
                save: { actions.add($0) }, delete: nil, close: { editing = nil }
            )
        }
    }
}
