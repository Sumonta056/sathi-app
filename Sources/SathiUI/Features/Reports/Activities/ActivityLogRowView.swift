import SathiCore
import SwiftUI

struct ActivityLogRowView: View {
    let row: ActivityLogRow
    let categories: [ActivityCategory]
    let calendar: Calendar
    let onEdit: () -> Void
    var onDelete: (ActivityID) -> Void = { _ in }
    let onFill: (DateInterval) -> Void
    let onSaveToCalendar: (ActivityID) -> Void

    var body: some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            switch row {
            case let .activity(a, running): activity(a, running: running)
            case let .gap(interval): gap(interval)
            }
        }
        .padding(.vertical, UIMetrics.trackerLogRowPadding)
    }

    private func activity(_ a: Activity, running: Bool) -> some View {
        let isAway = a.kind == .away
        return Group {
            Text(verbatim: span(a.start, running ? nil : a.end))
                .font(Typography.hint).foregroundStyle(Night.muted)
                .frame(width: UIMetrics.trackerLogTimeWidth, alignment: .leading)
            Circle()
                .fill(isAway ? Night.trackerAway : ActivityColors.color(a.category, in: categories))
                .frame(width: UIMetrics.dotSize, height: UIMetrics.dotSize)
            Text(verbatim: isAway ? Copywriter.trackerAwayText(a.awayPlace) : a.text)
                .font(Typography.rowLabel)
                .foregroundStyle(isAway ? Night.muted : Night.text)
                .lineLimit(1)
            Spacer(minLength: 0)
            if a.calendarID != nil, a.eventID == nil, !isAway {
                Button(Copywriter.trackerNotInCalendar + " · " + Copywriter.trackerSave) { onSaveToCalendar(a.id) }
                    .buttonStyle(GhostButton(accent: Night.trackerEvent, height: UIMetrics.trackerMiniButton))
            } else if a.eventID != nil || a.sourceEventID != nil {
                Image(systemName: "calendar").foregroundStyle(Night.trackerEvent).frame(width: UIMetrics.trackerLogIcon)
            }
            Text(verbatim: a.category ?? "")
                .font(Typography.hint).foregroundStyle(Night.muted)
                .frame(width: UIMetrics.trackerLogCategoryWidth, alignment: .leading)
            Text(verbatim: Copywriter.trackerDuration(a.length))
                .font(Typography.hint).foregroundStyle(Night.muted)
                .frame(width: UIMetrics.trackerLogLengthWidth, alignment: .trailing)
            if Self.canEdit(a, running: running) {
                Button(Copywriter.trackerEdit) { onEdit() }
                    .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
            } else if a.kind == .timeBlock {
                Button(Copywriter.trackerDelete) { onDelete(a.id) }
                    .buttonStyle(GhostButton(accent: Night.cheek, height: UIMetrics.trackerMiniButton))
            }
        }
    }

    @ViewBuilder
    private func gap(_ interval: DateInterval) -> some View {
        Text(verbatim: span(interval.start, interval.end))
            .font(Typography.hint).foregroundStyle(Night.muted)
            .frame(width: UIMetrics.trackerLogTimeWidth, alignment: .leading)
        Text(verbatim: Copywriter.trackerNotLogged)
            .font(Typography.rowLabel).foregroundStyle(Night.faint)
        Spacer(minLength: 0)
        Text(verbatim: Copywriter.trackerDuration(interval.duration))
            .font(Typography.hint).foregroundStyle(Night.muted)
            .frame(width: UIMetrics.trackerLogLengthWidth, alignment: .trailing)
        Button(Copywriter.trackerFill) { onFill(interval) }
            .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerMiniButton))
    }

    static func canEdit(_ a: Activity, running: Bool) -> Bool {
        !running && a.kind != .timeBlock
    }

    private func span(_ start: Date, _ end: Date?) -> String {
        guard let end else { return Copywriter.trackerClock(start, calendar: calendar) + " – " + Copywriter.trackerNow }
        return Copywriter.trackerSpan(start, end, calendar: calendar)
    }
}
