import SathiCore
import SwiftUI

struct CalendarDayCard: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let calendar: Calendar
    let categories: [ActivityCategory]
    let calendarName: String?
    var edit: () -> Void = {}

    var body: some View {
        switch laid.block.source {
        case .todo:
            EmptyView()
        case let .activity(activity, _):
            if activity.kind == .away || laid.block.style == .away {
                CalendarDayAwayFace(laid: laid, size: size, time: time, edit: edit)
            } else {
                CalendarDayActivityFace(laid: laid, activity: activity, size: size, time: time, categories: categories, edit: edit)
            }
        case .event:
            CalendarDayEventFace(laid: laid, size: size, time: time, calendarName: calendarName, edit: edit)
        }
    }

    private var time: String {
        Fmt.shortRange(laid.rounded.start, laid.rounded.end, calendar: calendar)
    }
}
