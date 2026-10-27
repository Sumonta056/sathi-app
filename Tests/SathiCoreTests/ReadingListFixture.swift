import Foundation
import SathiCore
import SathiTestSupport

enum Shelf {
    static let today = DayKey(raw: "2026-03-04")!

    static func key(_ raw: String) -> DayKey { DayKey(raw: raw)! }

    static func unread(_ name: String, title: String = "") -> ReadingItem {
        ReadingItem(title: title, url: URL(string: "https://\(name).com/post")!, addedOn: key("2026-03-01"))
    }

    static func read(_ name: String, on raw: String) -> ReadingItem {
        ReadingItem(title: "", url: URL(string: "https://\(name).com/post")!, addedOn: key("2026-02-01"), doneOn: key(raw))
    }

    static func unreadMany(_ count: Int) -> [ReadingItem] {
        (0 ..< count).map { unread("u\($0)") }
    }

    static func readMany(_ count: Int) -> [ReadingItem] {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 3))!
        return (0 ..< count).map {
            let date = Calendar.current.date(byAdding: .day, value: -$0, to: start)!
            return read("r\($0)", on: DayKey(date, calendar: .current).raw)
        }
    }

    @MainActor
    static func harness(_ list: [ReadingItem], at start: Date = day(2026, 3, 4, 10)) -> EngineHarness {
        EngineHarness(at: start) { $0.prefs.reading.list = list }
    }

    @MainActor
    static func list(_ h: EngineHarness) -> [ReadingItem] { h.engine.data.prefs.reading.list }

    @MainActor
    static func urls(_ h: EngineHarness) -> [String] { list(h).map(\.url.absoluteString) }
}
