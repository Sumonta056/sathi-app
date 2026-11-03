import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block widget")
struct BlockWidgetTests {
    @Test func showsTheTitleAndALiveTimer() throws {
        let h = Block.running(.minutes(30), after: 5)
        let sut = try Block.view(BlockWidget(), h)
        #expect(throws: Never.self) { try sut.find(text: "Plan") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.timer") }
    }

    @Test func anOpenBlockShowsALiveTimer() throws {
        let h = Block.running(.open, after: 42)
        let sut = try Block.view(BlockWidget(), h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.timer") }
    }

    @Test func aPlannedBlockCountsDownToItsEnd() throws {
        let h = Block.running(.minutes(30), after: 5)
        let b = try #require(h.engine.timeBlock)
        let t = BlockWidget.timer(b)
        #expect(t.countsDown)
        #expect(t.range.lowerBound == b.startedAt)
        #expect(t.range.upperBound == b.plannedEnd)
    }

    @Test func anOpenBlockCountsUpFromItsStart() throws {
        let h = Block.running(.open, after: 42)
        let b = try #require(h.engine.timeBlock)
        let t = BlockWidget.timer(b)
        #expect(!t.countsDown)
        #expect(t.range.lowerBound == b.startedAt)
    }

    @Test func aPlannedEndThatHasPassedStillRenders() throws {
        let h = Block.running(.minutes(30), after: 5)
        var b = try #require(h.engine.timeBlock)
        b.plannedEnd = h.engine.now.addingTimeInterval(-600)
        let sut = try BlockWidgetTimer(block: b).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.widget.timer") }
    }

    @Test func aPlannedEndBeforeTheStartClampsTheRange() throws {
        let h = Block.running(.minutes(30), after: 5)
        var b = try #require(h.engine.timeBlock)
        b.plannedEnd = b.startedAt.addingTimeInterval(-60)
        let t = BlockWidget.timer(b)
        #expect(t.range.lowerBound <= t.range.upperBound)
    }

    @Test func theEndButtonIsLabelledEndAndSave() throws {
        let sut = try Block.view(BlockWidget(), Block.running(.minutes(30), after: 5))
        let end = try sut.find(viewWithAccessibilityIdentifier: "block.widget.end")
        let labelled = try? end.accessibilityLabel().string()
        let parent = try? end.find(ViewType.Button.self, relation: .parent).accessibilityLabel().string()
        #expect(labelled == "End and save" || parent == "End and save")
    }

    @Test func theEndButtonEndsAndSavesTheBlock() throws {
        let h = Block.running(.minutes(30), after: 18)
        try Block.tap(Block.view(BlockWidget(), h), id: "block.widget.end")
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.saved.first?.title == "Plan")
    }

    @Test func theEndButtonOnAShortBlockSavesNothing() throws {
        let h = Block.running(.minutes(30), after: 0)
        try Block.tap(Block.view(BlockWidget(), h), id: "block.widget.end")
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }
}

@MainActor
@Suite("Block widget hover")
struct BlockWidgetHoverTests {
    @Test func theHintShowsTheEndAndTheCalendar() throws {
        let h = Block.running(.minutes(30), after: 5)
        let b = try #require(h.engine.timeBlock)
        let end = Block.clock(Block.now.addingTimeInterval(30 * 60))
        #expect(BlockWidget.hint(b, h.engine) == "ends " + end + " · Gmail Work")
    }

    @Test func aGoneCalendarFallsBackToItsSavedTitle() throws {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.engine.refreshCalendarAccess()
        let b = try #require(h.engine.timeBlock)
        #expect(BlockWidget.hint(b, h.engine).hasSuffix(" · Gmail Work"))
    }

    @Test func noTitleAnywhereSaysYourCalendar() throws {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.engine.refreshCalendarAccess()
        var b = try #require(h.engine.timeBlock)
        b.calendarTitle = nil
        #expect(BlockWidget.hint(b, h.engine).hasSuffix(" · your calendar"))
    }

    @Test func hoveringSwapsTheTitleForTheHint() throws {
        let sut = try BlockWidgetTitle(title: "Plan", hint: "ends 10:30 AM · Work", hovering: true).inspect()
        #expect(throws: Never.self) { try sut.find(text: "ends 10:30 AM · Work") }
        #expect((try? sut.find(text: "Plan")) == nil)
    }

    @Test func notHoveringShowsTheTitle() throws {
        let sut = try BlockWidgetTitle(title: "Plan", hint: "ends 10:30 AM · Work", hovering: false).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Plan") }
    }
}
