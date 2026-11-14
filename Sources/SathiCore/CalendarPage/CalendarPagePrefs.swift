import Foundation

package struct CalendarPagePrefs: Codable, Equatable, Sendable {
    package var isOn = false
    package var hiddenCalendarIDs: Set<String> = []
    package var lastCalendarID: String?
    package var sidePanelShown = true

    package init() {}

    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CalendarPagePrefs()
        isOn = c.lenient(.isOn, or: d.isOn)
        hiddenCalendarIDs = c.lenientSet(.hiddenCalendarIDs, or: [])
        lastCalendarID = c.lenient(.lastCalendarID, or: String?.none)
        sidePanelShown = c.lenient(.sidePanelShown, or: d.sidePanelShown)
    }
}
