import Foundation

extension Copywriter {
    package static let calendarDayInCalendar = "Calendar"
    package static let calendarDayNotInCalendar = trackerNotInCalendar

    package static func calendarDayActual(_ tracked: TimeInterval) -> String {
        "Actual · " + calendarBlockLength(DateInterval(start: .distantPast, duration: max(0, tracked)))
    }

    package static func calendarDayPlan(_ events: Int) -> String {
        "Plan · \(events) event" + (events == 1 ? "" : "s")
    }

    package static func calendarDayDoneDuring(_ count: Int) -> String {
        "\(count) done during"
    }

    package static func calendarDayEditLabel(_ title: String) -> String {
        "Edit " + title
    }
}
