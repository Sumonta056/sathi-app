import Foundation

package enum CalendarTitleMatch {
    package static func joins(_ a: Activity, _ e: CalendarEventInfo) -> Bool {
        a.kind != .away
            && trimmed(a.text).lowercased() == trimmed(e.title).lowercased()
            && a.start < e.end
            && e.start < a.end
    }

    package static func copies(_ events: [CalendarEventInfo]) -> [(event: CalendarEventInfo, count: Int)] {
        var result: [(event: CalendarEventInfo, count: Int)] = []
        for e in events {
            if !e.isAllDay, let i = result.firstIndex(where: { same($0.event, e) }) {
                result[i].count += 1
                if e.calendarID < result[i].event.calendarID { result[i].event = e }
            } else {
                result.append((e, 1))
            }
        }
        return result
    }

    private static func same(_ a: CalendarEventInfo, _ b: CalendarEventInfo) -> Bool {
        !a.isAllDay && a.calendarID != b.calendarID && a.start == b.start && a.end == b.end && trimmed(a.title) == trimmed(b.title)
    }

    private static func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
