import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Todo mapping")
struct TodoMappingTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }

    @Test("not determined maps to notAsked, granted to allowed, the rest to denied")
    func access() {
        #expect(TodoMapping.access(notDetermined: true, granted: false) == .notAsked)
        #expect(TodoMapping.access(notDetermined: false, granted: true) == .allowed)
        #expect(TodoMapping.access(notDetermined: false, granted: false) == .denied)
    }

    @Test func dueComponentsWithAnHourAreTimed() {
        let c = DateComponents(year: 2026, month: 3, day: 5, hour: 14, minute: 30)
        #expect(TodoMapping.due(from: c, calendar: cal) == TodoDue(date: z.date(2026, 3, 5, 14, 30), hasTime: true))
    }

    @Test func dueComponentsWithoutAnHourAreDateOnlyAtTheStartOfTheDay() {
        let c = DateComponents(year: 2026, month: 3, day: 5)
        #expect(TodoMapping.due(from: c, calendar: cal) == TodoDue(date: z.date(2026, 3, 5), hasTime: false))
    }

    @Test func dueComponentsWithoutADayGiveNil() {
        #expect(TodoMapping.due(from: DateComponents(), calendar: cal) == nil)
    }

    @Test func timedDueBecomesFullComponents() {
        let c = TodoMapping.components(for: TodoDue(date: z.date(2026, 3, 5, 14, 30), hasTime: true), calendar: cal)
        #expect([c.year, c.month, c.day, c.hour, c.minute] == [2026, 3, 5, 14, 30])
    }

    @Test func dateOnlyDueBecomesComponentsWithoutATime() {
        let c = TodoMapping.components(for: TodoDue(date: z.date(2026, 3, 5, 17), hasTime: false), calendar: cal)
        #expect([c.year, c.month, c.day] == [2026, 3, 5])
        #expect(c.hour == nil)
        #expect(c.minute == nil)
    }

    @Test func colorHexClampsAndUppercases() {
        #expect(TodoMapping.colorHex(red: 1, green: 0.5, blue: 0) == "#FF8000")
        #expect(TodoMapping.colorHex(red: 2, green: -1, blue: 1) == "#FF00FF")
    }

    @Test func rgbFromHexRoundTrips() throws {
        let c = try #require(TodoMapping.rgb(fromHex: "#FF8000"))
        #expect(c.red == 1)
        #expect(abs(c.green - 128.0 / 255.0) < 0.0001)
        #expect(c.blue == 0)
        #expect(TodoMapping.rgb(fromHex: "nope") == nil)
    }

    @Test func listsSortByAccountThenName() {
        let lists = [
            makeTodoList("1", "B"),
            makeTodoList("2", "A"),
            TodoList(id: "3", name: "Z", colorHex: "#FF3B30", accountID: "ex", accountName: "Exchange", canEdit: true)
        ]
        #expect(TodoMapping.sorted(lists).map(\.id) == ["3", "2", "1"])
    }
}
