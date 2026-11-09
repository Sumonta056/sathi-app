import Foundation

extension Engine {
    package var activityReportDay: DayKey? { trackerRuntime.reportDay }

    package func activityDay(_ day: DayKey) -> ActivityDay {
        let start = day.start(in: calendar)
        return ActivityDay(day: day, hours: DateInterval(start: start, duration: 0), activities: [])
    }

    package func activityDays(in month: MonthKey) -> [ActivityDay] { [] }
    package func daysWithActivities(in month: MonthKey) -> Set<DayKey> { [] }

    @discardableResult
    package func editActivity(_ id: ActivityID, _ edit: ActivityEdit) -> ActivityEditResult { .notFound }

    @discardableResult
    package func addPastActivity(_ edit: ActivityEdit) -> ActivityEditResult { .notFound }

    package func deleteActivity(_ id: ActivityID) {}
}
