import Foundation

package struct ActivityDay: Equatable, Sendable {
    package var day: DayKey
    package var hours: DateInterval
    package var activities: [Activity]
    package var running: Activity?

    package init(day: DayKey, hours: DateInterval, activities: [Activity], running: Activity? = nil) {
        self.day = day
        self.hours = hours
        self.activities = activities
        self.running = running
    }
}
