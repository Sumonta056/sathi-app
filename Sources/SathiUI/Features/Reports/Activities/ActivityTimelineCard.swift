import SathiCore
import SwiftUI

struct ActivityTimelineCard: View {
    let day: ActivityDay
    let count: Int
    let gaps: [DateInterval]
    let categories: [ActivityCategory]
    let calendar: Calendar
    let calendars: [CalendarChoice]
    let calendarNames: [String: String]
    let actions: ActivityDayActions
    var canUndo = false
    @Binding var editing: ActivityEditTarget?
    @Binding var selected: Set<ActivityID>
    @Binding var mergeError: String?
    @State private var memo = ActivityMergeCheckMemo()

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesTileRadius, style: .continuous)
        let rows = ActivityLogRows.make(day, gaps: gaps)
        VStack(alignment: .leading, spacing: UIMetrics.activitiesCardGap) {
            header(rows)
            ActivityRibbon(
                segments: ActivityTimeline.segments(day), hours: day.hours, categories: categories,
                height: UIMetrics.activitiesLaneHeight, radius: UIMetrics.activitiesLaneRadius, showsLabels: false
            )
            ActivityAxis(hours: day.hours, calendar: calendar)
            if ActivityMergeBar.shows(selected: selected, canUndo: canUndo, error: mergeError) {
                ActivityMergeBar(
                    check: mergeCheck, calendar: calendar, canUndo: canUndo,
                    actions: actions, selected: $selected, error: $mergeError
                )
            }
            ActivityTimelineList(
                rows: rows, categories: categories, calendar: calendar, calendarNames: calendarNames,
                editing: editing, selected: selected, onToggle: toggle, onEdit: { editing = .activity($0) }, onFill: { editing = .add($0) },
                onDelete: delete
            )
        }
        .padding(UIMetrics.activitiesCardPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func toggle(_ id: ActivityID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        mergeError = nil
    }

    private func delete(_ id: ActivityID) {
        _ = actions.delete(id)
        selected.remove(id)
    }

    private var mergeCheck: ManualMergeCheck? {
        guard !selected.isEmpty else { return nil }
        return memo.value(selected, rows: day.activities, make: actions.mergeCheck)
    }

    private func header(_ rows: [ActivityLogRow]) -> some View {
        HStack(spacing: UIMetrics.activitiesColumnGap) {
            Text(verbatim: Copywriter.activitiesTimeline)
                .font(Typography.tracker(UIMetrics.activitiesTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: Copywriter.activitiesCountLine(
                count, gaps: rows.filter { !ActivityTimelineList.isActivity($0) }.count
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
}
