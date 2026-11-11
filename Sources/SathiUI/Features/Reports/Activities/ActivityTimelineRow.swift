import SathiCore
import SwiftUI

struct ActivityTimelineRow: View {
    let activity: Activity
    var running = false
    let categories: [ActivityCategory]
    let calendar: Calendar
    var calendarName: String?
    var selected = false
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    private var isAway: Bool { activity.kind == .away }
    private var color: Color { isAway ? Night.trackerAway : ActivityColors.color(activity.category, in: categories) }
    private var title: String { isAway ? activity.awayText : activity.text }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesRowRadius, style: .continuous)
        HStack(spacing: UIMetrics.activitiesRowInner) {
            if isAway { awayText } else { workText }
            Text(verbatim: Copywriter.activitiesLength(activity.length))
                .font(Typography.tracker(UIMetrics.activitiesRowTitleFont, .bold))
                .foregroundStyle(isAway ? Night.muted : Night.text)
                .fixedSize()
            action
        }
        .padding(UIMetrics.activitiesRowPadding)
        .frame(height: Self.height(activity), alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(isAway ? Night.card : color.opacity(UIMetrics.activitiesRowTint)))
        .overlay(alignment: .leading) { color.frame(width: UIMetrics.activitiesRowBar) }
        .clipShape(shape)
        .overlay(shape.strokeBorder(
            selected ? color : isAway ? Night.border : .clear,
            lineWidth: selected ? UIMetrics.activitiesRowOutline : UIMetrics.cardBorder
        ))
    }

    static func height(_ a: Activity) -> CGFloat {
        if a.kind == .away { return UIMetrics.activitiesRowAway }
        let hour = TimeInterval(Limits.minutesPerHour) * Timing.minute
        if a.length < hour { return UIMetrics.activitiesRowShort }
        return a.length <= hour * 2 ? UIMetrics.activitiesRowMedium : UIMetrics.activitiesRowLong
    }

    static func canEdit(_ a: Activity, running: Bool) -> Bool {
        !running && a.kind != .timeBlock
    }

    private var span: String {
        guard !running else { return Copywriter.trackerClock(activity.start, calendar: calendar) + " – " + Copywriter.trackerNow }
        return Copywriter.trackerSpan(activity.start, activity.end, calendar: calendar)
    }

    private var workText: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.activitiesRowTitleFont, .bold))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(spacing: UIMetrics.activitiesRowDetailGap) {
                detail(span, Night.chipText)
                if let category = activity.category { detail(category, color, weight: .bold) }
                if activity.eventID != nil || activity.sourceEventID != nil {
                    HStack(spacing: UIMetrics.textSpacing) {
                        Image(systemName: "calendar").font(.system(size: UIMetrics.activitiesRowIcon))
                        if let calendarName { Text(verbatim: calendarName) }
                    }
                    .font(Typography.tracker(UIMetrics.activitiesRowDetailFont, .medium))
                    .foregroundStyle(Night.trackerEvent)
                    .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var awayText: some View {
        HStack(spacing: UIMetrics.textSpacing) {
            Text(verbatim: title).font(Typography.tracker(UIMetrics.activitiesRowTitleFont, .bold)).lineLimit(1)
            detail("· " + span, Night.muted)
        }
        .foregroundStyle(Night.muted)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detail(_ text: String, _ color: Color, weight: Font.Weight = .medium) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.activitiesRowDetailFont, weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
    }

    @ViewBuilder private var action: some View {
        if Self.canEdit(activity, running: running) {
            iconButton("pencil", label: Copywriter.activitiesEditLabel(title), action: onEdit)
        } else if activity.kind == .timeBlock {
            iconButton("trash", label: Copywriter.trackerDelete + " " + title, action: onDelete)
        }
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesPencilRadius, style: .continuous)
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.activitiesPencilIcon, weight: .semibold))
                .foregroundStyle(Night.chipText)
                .frame(width: UIMetrics.activitiesPencil, height: UIMetrics.activitiesPencil)
                .background(shape.fill(isAway ? Night.trackerInset : Night.card))
                .overlay(shape.strokeBorder(color.opacity(UIMetrics.activitiesPencilTint), lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}
