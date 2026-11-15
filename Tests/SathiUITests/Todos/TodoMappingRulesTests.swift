import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Todo mapping rules")
struct TodoMappingRulesTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }

    private func src(_ id: String, calDAV: Bool = true, lists: Bool = true) -> TodoSourceInfo {
        TodoSourceInfo(id: id, isCalDAV: calDAV, hasReminderLists: lists)
    }

    @Test func theDefaultSourceWinsWhenItIsCalDAV() {
        let sources = [src("a"), src("b")]
        #expect(TodoMapping.iCloudSourceID(defaultSourceID: "b", sources: sources) == "b")
    }

    @Test func aNonCalDAVDefaultFallsBackToTheOnlyCalDAVSourceWithLists() {
        let sources = [src("local", calDAV: false), src("g", lists: false), src("ic")]
        #expect(TodoMapping.iCloudSourceID(defaultSourceID: "local", sources: sources) == "ic")
    }

    @Test func severalCalDAVSourcesGiveTheFirstWithLists() {
        let sources = [src("ex", calDAV: false), src("empty", lists: false), src("one"), src("two")]
        #expect(TodoMapping.iCloudSourceID(defaultSourceID: nil, sources: sources) == "one")
    }

    @Test func noCalDAVSourceWithListsFlagsNothing() {
        let sources = [src("ex", calDAV: false), src("empty", lists: false)]
        #expect(TodoMapping.iCloudSourceID(defaultSourceID: "ex", sources: sources) == nil)
        #expect(TodoMapping.iCloudSourceID(defaultSourceID: nil, sources: []) == nil)
    }

    @Test func alarmsAtTheOldDueMoveToTheNewDue() {
        let old = z.date(2026, 3, 5, 9)
        let new = z.date(2026, 3, 6, 10)
        let other = z.date(2026, 3, 5, 8)
        #expect(TodoMapping.alarmDates(oldDue: old, newDue: new, alarms: [old, other]) == [new, other])
    }

    @Test func removingTheDueRemovesTheMatchingAlarms() {
        let old = z.date(2026, 3, 5, 9)
        let other = z.date(2026, 3, 5, 8)
        #expect(TodoMapping.alarmDates(oldDue: old, newDue: nil, alarms: [old, other]) == [nil, other])
    }

    @Test func withoutAnOldDueNoAlarmMoves() {
        let other = z.date(2026, 3, 5, 8)
        #expect(TodoMapping.alarmDates(oldDue: nil, newDue: z.date(2026, 3, 6), alarms: [other]) == [other])
    }

    @Test func dueHonorsTheComponentsTimeZone() throws {
        var c = DateComponents(year: 2026, month: 3, day: 5, hour: 14, minute: 0)
        c.timeZone = TimeZone(identifier: "UTC")
        let due = TodoMapping.due(from: c, calendar: cal)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try #require(TimeZone(identifier: "UTC"))
        #expect(try due == TodoDue(date: #require(utc.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 14))), hasTime: true))
    }
}
