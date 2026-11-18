import Foundation

extension CalendarHoverInfo {
    static func rows(_ blocks: [CalendarBlock], calendar: Calendar, short: Bool = true) -> [CalendarHoverChild] {
        blocks.flatMap(\.rows).map {
            let i = $0.interval
            let time = short ? Fmt.shortRange(i.start, i.end, calendar: calendar) : Copywriter.trackerSpan(i.start, i.end, calendar: calendar)
            return CalendarHoverChild(id: $0.id, title: $0.title, time: time)
        }
    }
}
