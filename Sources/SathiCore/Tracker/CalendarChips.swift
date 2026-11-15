import Foundation

package enum CalendarChips {
    package static func shown(
        _ calendars: [CalendarChoice], picked: String?, all: Bool, limit: Int = Limits.promptCalendarsShown
    ) -> [CalendarChoice] {
        guard !all, calendars.count > limit else { return calendars }
        let head = Array(calendars.prefix(limit))
        guard let picked, !head.contains(where: { $0.id == picked }),
              let chosen = calendars.first(where: { $0.id == picked }) else { return head }
        return Array(head.prefix(limit - 1)) + [chosen]
    }

    package static func label(_ c: CalendarChoice, in calendars: [CalendarChoice]) -> String {
        let shared = calendars.contains { $0.id != c.id && $0.title == c.title }
        guard shared, !c.account.isEmpty else { return c.title }
        return c.title + " · " + c.account
    }
}
