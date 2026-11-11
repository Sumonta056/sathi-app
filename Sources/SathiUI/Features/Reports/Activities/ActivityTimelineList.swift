import SathiCore
import SwiftUI

enum ActivityEditTarget: Equatable {
    case activity(ActivityID)
    case add(DateInterval)

    var key: String {
        switch self {
        case let .activity(id): return id.raw.uuidString
        case let .add(i): return "add-\(i.start.timeIntervalSince1970)-\(i.end.timeIntervalSince1970)"
        }
    }
}

struct ActivityTimelineList: View {
    let rows: [ActivityLogRow]
    let categories: [ActivityCategory]
    let calendar: Calendar
    var calendarNames: [String: String] = [:]
    var editing: ActivityEditTarget?
    var onEdit: (ActivityID) -> Void = { _ in }
    var onFill: (DateInterval) -> Void = { _ in }
    var onDelete: (ActivityID) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.activitiesRowGap) {
            if !rows.contains(where: Self.isActivity) {
                Text(verbatim: Copywriter.trackerNoActivities).font(Typography.hint).foregroundStyle(Night.muted)
            }
            ForEach(rows) { row in
                HStack(alignment: .top, spacing: UIMetrics.activitiesColumnGap) {
                    Text(verbatim: Copywriter.trackerClock(start(row), calendar: calendar))
                        .font(Typography.tracker(UIMetrics.activitiesTimeFont, .medium))
                        .foregroundStyle(Night.faint)
                        .frame(width: UIMetrics.activitiesTimeWidth, alignment: .leading)
                        .padding(.top, UIMetrics.activitiesTimeTop)
                    content(row)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    static func isActivity(_ row: ActivityLogRow) -> Bool {
        if case .activity = row { return true }
        return false
    }

    private func start(_ row: ActivityLogRow) -> Date {
        switch row {
        case let .activity(a, _): return a.start
        case let .gap(i): return i.start
        }
    }

    @ViewBuilder private func content(_ row: ActivityLogRow) -> some View {
        switch row {
        case let .activity(a, running):
            ActivityTimelineRow(
                activity: a, running: running, categories: categories, calendar: calendar,
                calendarName: a.calendarID.flatMap { calendarNames[$0] }, selected: editing == .activity(a.id),
                onEdit: { onEdit(a.id) }, onDelete: { onDelete(a.id) }
            )
        case let .gap(interval):
            ActivityGapRow(interval: interval, calendar: calendar) { onFill(interval) }
        }
    }
}
