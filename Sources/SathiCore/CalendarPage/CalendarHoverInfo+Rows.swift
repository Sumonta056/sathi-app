import Foundation

extension CalendarHoverInfo {
    static func rows(_ blocks: [CalendarBlock], calendar: Calendar) -> [CalendarHoverChild] {
        blocks.flatMap(\.rows).map {
            let i = CalendarRounding.rounded($0.interval)
            return CalendarHoverChild(id: $0.id, title: $0.title, time: Fmt.shortRange(i.start, i.end, calendar: calendar))
        }
    }
}
