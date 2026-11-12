import Foundation

package struct TrackerEndOfDayState {
    package var day: ActivityDay
    package var categories: [ActivityCategory]
    package var calendar: Calendar = .current
    package var openReport: @MainActor () -> Void = {}
    package var close: @MainActor () -> Void = {}

    package init(day: ActivityDay, categories: [ActivityCategory]) {
        self.day = day
        self.categories = categories
    }
}
