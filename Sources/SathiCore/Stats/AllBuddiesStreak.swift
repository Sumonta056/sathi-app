import Foundation

package enum AllBuddiesStreak {
    package static func current(now: Date, calendar: Calendar, judge: (DateInterval) -> BuddyDayJudge) -> Int {
        let cal = Calendar.gregorian(in: calendar.timeZone)
        var day = cal.startOfDay(for: now)
        guard var month = cal.dateInterval(of: .month, for: day) else { return 0 }
        var current = judge(month)
        guard !current.buddies.isEmpty else { return 0 }
        var count = current.isStreakDay(day) == true ? 1 : 0
        for _ in 1 ..< Limits.streakLookbackDays {
            day = cal.previousDay(before: day)
            if day < month.start, let earlier = cal.dateInterval(of: .month, for: day) {
                month = earlier
                current = judge(month)
            }
            switch current.isStreakDay(day) {
            case true?: count += 1
            case false?: return count
            case nil: continue
            }
        }
        return count
    }
}
