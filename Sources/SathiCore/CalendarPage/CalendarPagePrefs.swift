import Foundation

package struct CalendarPagePrefs: Codable, Equatable, Sendable {
    package var isOn = false
    package var hiddenCalendarIDs: Set<String> = []
    package var lastCalendarID: String?
    package var sidePanelShown = true
    package var sidePanelShownWeek = false
    package var rowMinutes = Limits.calendarDefaultRowMinutes

    package init() {}

    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CalendarPagePrefs()
        isOn = c.lenient(.isOn, or: d.isOn)
        hiddenCalendarIDs = c.lenientSet(.hiddenCalendarIDs, or: [])
        lastCalendarID = c.lenient(.lastCalendarID, or: String?.none)
        sidePanelShown = c.lenient(.sidePanelShown, or: d.sidePanelShown)
        sidePanelShownWeek = c.lenient(.sidePanelShownWeek, or: d.sidePanelShownWeek)
        let minutes = c.lenient(.rowMinutes, or: d.rowMinutes)
        rowMinutes = Limits.calendarRowMinutes.contains(minutes) ? minutes : d.rowMinutes
    }

    package func sidePanelShown(for kind: ReportRange) -> Bool {
        kind == .week ? sidePanelShownWeek : sidePanelShown
    }
}
