import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page has no Merge")
struct CalendarNoMergeTests {
    private static let first = Activity(text: "Write", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 30))
    private static let second = Activity(text: "Review", category: "Coding", start: day(2026, 3, 4, 10, 30), end: day(2026, 3, 4, 11))

    private func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [Self.first, Self.second])) {
            $0.prefs.tracker.isOn = true
        }
        h.engine.refreshCalendarAccess()
        return h
    }

    private func page(_ h: EngineHarness, _ kind: ReportRange) throws -> InspectableView<ViewType.ClassifiedView> {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range).environmentObject(h.engine).inspect()
    }

    private func ids(_ sut: InspectableView<ViewType.ClassifiedView>) -> [String] {
        sut.findAll(where: { (try? $0.accessibilityIdentifier()) != nil }).compactMap { try? $0.accessibilityIdentifier() }
    }

    @Test(arguments: [ReportRange.day, .week])
    func noMergeTextAnywhereOnThePage(_ kind: ReportRange) throws {
        let sut = try page(harness(), kind)
        #expect(sut.findAll(ViewType.Text.self, where: { try $0.string().localizedCaseInsensitiveContains("merge") }).isEmpty)
    }

    @Test(arguments: [ReportRange.day, .week])
    func noMergeStripCheckboxOrSelection(_ kind: ReportRange) throws {
        let found = try ids(page(harness(), kind))
        #expect(!found.contains { $0.contains("merge") || $0.contains("select") || $0.contains("check") })
    }

    @Test func theGridActionsHaveNoCommandClickSelection() {
        let labels = Mirror(reflecting: CalendarGridActions()).children.compactMap(\.label)
        #expect(Set(labels) == ["slot", "block", "failed"])
    }

    @Test func activityHoverActionsAreEditAndDeleteOnly() throws {
        let h = harness()
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: .day, calendar: h.engine.rangeCalendar)
        let block = try #require(h.engine.calendarPageBase(range).blocks.first { $0.title == "Write" })
        let laid = CalendarLaidBlock(block: block, span: block.interval, half: .actual)
        #expect(CalendarHoverRun.visible(h.engine.calendarHoverInfo(laid, among: [laid])) == [.edit, .delete])
    }
}
