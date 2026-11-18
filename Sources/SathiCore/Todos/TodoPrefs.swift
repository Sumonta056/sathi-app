import Foundation

package struct TodoPrefs: Codable, Equatable, Sendable {
    package var isOn: Bool = false
    package var hiddenListIDs: Set<String> = []
    package var askWhenDue: Bool = true
    package var newListAccountID: String?
    package var order: [String: [String]] = [:]

    package init(
        isOn: Bool = false,
        hiddenListIDs: Set<String> = [],
        askWhenDue: Bool = true,
        newListAccountID: String? = nil
    ) {
        self.isOn = isOn
        self.hiddenListIDs = hiddenListIDs
        self.askWhenDue = askWhenDue
        self.newListAccountID = newListAccountID
    }

    private enum CodingKeys: String, CodingKey {
        case isOn, hiddenListIDs, askWhenDue, newListAccountID, order
    }

    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TodoPrefs()
        isOn = c.lenient(.isOn, or: d.isOn)
        hiddenListIDs = c.lenientSet(.hiddenListIDs, or: d.hiddenListIDs)
        askWhenDue = c.lenient(.askWhenDue, or: d.askWhenDue)
        newListAccountID = try? c.decodeIfPresent(String.self, forKey: .newListAccountID)
        order = c.lenient(.order, or: d.order)
    }
}
