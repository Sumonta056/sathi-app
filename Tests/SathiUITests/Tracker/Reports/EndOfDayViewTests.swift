import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("End of day view")
struct EndOfDayViewTests {
    typealias Fix = ActivityViewSupport

    private func state(opened: @escaping () -> Void = {}, closed: @escaping () -> Void = {}) -> TrackerEndOfDayState {
        var s = TrackerEndOfDayState(day: Fix.day(), categories: ActivityCategory.defaults)
        s.calendar = Fix.calendar
        s.openReport = opened
        s.close = closed
        return s
    }

    private func press(_ sut: EndOfDayView, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func showsTheTotalsAndFacts() throws {
        let sut = try EndOfDayView(state: state()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "2 h of real work") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerYourDayEyebrow(Fix.at(4, 12), calendar: Fix.calendar)) }
    }

    @Test func copyForStandupCopiesTheStandupText() throws {
        var copied: String?
        let sut = EndOfDayView(state: state(), copy: { copied = $0 })
        try press(sut, "Copy for standup")
        #expect(copied == ActivityStandupText.make(Fix.day(), calendar: Fix.calendar))
    }

    @Test func openFullReportAndCloseCallTheState() throws {
        var opened = 0
        var closed = 0
        let sut = EndOfDayView(state: state(opened: { opened += 1 }, closed: { closed += 1 }))
        try press(sut, "Open full report")
        try press(sut, "Close")
        #expect(opened == 1)
        #expect(closed == 1)
    }

    @Test func notLoggedTimeOffersToFillIt() throws {
        #expect(throws: Never.self) { try EndOfDayView(state: state()).inspect().find(text: "Fill it in the report") }
    }
}
