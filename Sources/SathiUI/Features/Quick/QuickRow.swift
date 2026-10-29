import SathiCore
import SwiftUI

struct QuickRow: View {
    @EnvironmentObject var e: Engine
    let item: QuickReminder

    var body: some View {
        let calendar = Calendar.gregorian(in: e.timeZone)
        HStack(spacing: UIMetrics.quickTimeSpacing) {
            Text(verbatim: Copywriter.quickClock(item.fireDate, calendar: calendar))
                .font(Typography.pill)
                .foregroundStyle(Night.quick)
                .frame(minWidth: UIMetrics.quickPillWidth)
                .padding(UIMetrics.quickBadgePadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.quickPillRadius, style: .continuous).fill(Night.quickFill))
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: item.text)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                Text(verbatim: Copywriter.quickWhen(
                    item.fireDate,
                    now: e.now,
                    showing: e.quickActivities[item.id] != nil,
                    calendar: calendar
                ))
                .font(Typography.pill)
                .foregroundStyle(Night.label)
            }
            Spacer(minLength: 0)
            Button { e.removeQuick(item.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.quickDeleteIcon, weight: .heavy))
                    .foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.quickDeleteSize, height: UIMetrics.quickDeleteSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "Delete this reminder"))
        }
        .frame(height: UIMetrics.quickRowHeight)
        .overlay(alignment: .top) {
            Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
        }
    }
}
