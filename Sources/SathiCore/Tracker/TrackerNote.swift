import Foundation

package enum TrackerNote: Equatable, Sendable {
    case event(CalendarEventInfo)
    case alsoNow(CalendarEventInfo)

    package var event: CalendarEventInfo {
        switch self {
        case let .event(e), let .alsoNow(e): return e
        }
    }
}
