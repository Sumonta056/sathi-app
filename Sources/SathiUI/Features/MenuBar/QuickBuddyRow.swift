import SathiCore
import SwiftUI

struct QuickBuddyRow: View {
    @EnvironmentObject var e: Engine
    let buddy: TodayBuddy

    var body: some View {
        HStack(spacing: UIMetrics.quickRowSpacing) {
            Circle()
                .fill(Night.accent(buddy.habit))
                .frame(width: UIMetrics.quickBuddyDot, height: UIMetrics.quickBuddyDot)
                .accessibilityHidden(true)
            Text(verbatim: buddy.habit.buddy)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.quickPanelStatus(buddy, calendar: e.calendar))
                .font(Typography.hint)
                .foregroundStyle(buddy.status == .met ? Night.sprout : Night.muted)
                .lineLimit(1)
            if buddy.habit == .water, buddy.status != .off {
                Button { e.logWater(1) } label: {
                    Text(verbatim: Copywriter.quickPanelPlusGlass)
                }
                .buttonStyle(GhostButton(accent: Night.water, height: UIMetrics.quickSmallButtonHeight))
                .accessibilityIdentifier("quick.glass")
            }
            DoNowButton(e: e, habit: buddy.habit, before: MenuBarWindow.close)
        }
        .padding(UIMetrics.quickBuddyRowPadding)
    }
}
