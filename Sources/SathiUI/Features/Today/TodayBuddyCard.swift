import SathiCore
import SwiftUI

struct TodayBuddyCard: View {
    let e: Engine
    let buddy: TodayBuddy
    let calendar: Calendar

    var body: some View {
        let accent = Night.accent(buddy.habit)
        VStack(alignment: .leading, spacing: UIMetrics.todayBuddyGap) {
            HStack {
                Text(verbatim: buddy.habit.buddy)
                    .font(Typography.tracker(UIMetrics.todayBuddyNameFont, .bold))
                    .foregroundStyle(Night.text)
                Spacer(minLength: 0)
                Text(verbatim: buddy.habit.name)
                    .font(Typography.tracker(UIMetrics.todayBuddyKindFont, .regular))
                    .foregroundStyle(accent)
            }
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(verbatim: buddy.total)
                    .font(Typography.tracker(UIMetrics.todayBuddyValueFont, .heavy))
                    .foregroundStyle(Night.text)
                Text(verbatim: Copywriter.todayGoalLine(goal: buddy.goal, unit: buddy.unit))
                    .font(Typography.tracker(UIMetrics.todayBuddyUnitFont, .semibold))
                    .foregroundStyle(Night.muted)
                    .lineLimit(1)
            }
            bar(accent)
            status
        }
        .padding(UIMetrics.todayBuddyPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).fill(Night.card))
        .overlay(RoundedRectangle(cornerRadius: UIMetrics.todayCardRadius, style: .continuous).stroke(Night.border))
    }

    private func bar(_ accent: Color) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: UIMetrics.todayBarRadius).fill(Night.divider)
                RoundedRectangle(cornerRadius: UIMetrics.todayBarRadius)
                    .fill(accent)
                    .frame(width: g.size.width * ProgressRing.clamp(buddy.progress))
            }
        }
        .frame(height: UIMetrics.todayBarHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copywriter.todayBuddyProgress(buddy.habit.name))
        .accessibilityValue(ProgressRing.percent(buddy.progress))
    }

    private var status: some View {
        HStack(spacing: 0) {
            Text(verbatim: statusText)
                .font(Typography.tracker(UIMetrics.todayBuddyStatusFont, buddy.status == .met ? .semibold : .regular))
                .foregroundStyle(buddy.status == .met ? Night.sprout : Night.muted)
            if buddy.status != .off {
                Spacer(minLength: 0)
                DoNowButton(e: e, habit: buddy.habit)
            }
        }
        .lineLimit(1)
    }

    private var statusText: String {
        switch buddy.status {
        case .met: return Copywriter.todayGoalMet
        case .dayOff: return Copywriter.todayDayOff
        case .off: return Copywriter.todayOff
        case .noReminder: return Copywriter.todayNoReminder
        case .dueNow: return Copywriter.todayDueNow
        case .paused: return Copywriter.todayPaused
        case let .snoozed(time): return Copywriter.todaySnoozed(until: time, calendar: calendar)
        case let .next(time): return Copywriter.todayNextAt(time, calendar: calendar)
        case let .gymSession(n, of: m, time): return Copywriter.todayGymSession(n, of: m, at: time, calendar: calendar)
        }
    }
}
