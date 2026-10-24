import Foundation

package protocol HistoryStore: AnyObject {
    func append(_ event: HistoryEvent)
    func events(from start: Date, to end: Date) -> [HistoryEvent]
    func allEvents() -> [HistoryEvent]
    @discardableResult
    func flush() -> Bool
}
