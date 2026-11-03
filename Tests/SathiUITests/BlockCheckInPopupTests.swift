import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Block check-in popup")
struct BlockCheckInPopupTests {
    @Test func showsEyebrowQuestionAndStartTime() throws {
        let h = Block.checkIn()
        let sut = try Block.view(BlockCheckInPopup(), h)
        let started = Block.clock(Block.now)
        #expect(throws: Never.self) { try sut.find(text: "TIME BLOCK · 2 HOURS") }
        #expect(throws: Never.self) { try sut.find(text: "Still on Plan?") }
        #expect(throws: Never.self) { try sut.find(text: "Started at " + started + ". Sathi asks again in 2 hours.") }
    }

    @Test func offersKeepGoingAndEndNow() throws {
        let sut = try Block.view(BlockCheckInPopup(), Block.checkIn())
        #expect(throws: Never.self) { try sut.find(text: "Keep going") }
        #expect(throws: Never.self) { try sut.find(text: "End now") }
    }

    @Test func keepGoingKeepsTheBlockAndAsksAgainInTwoHours() throws {
        let h = Block.checkIn()
        #expect(h.engine.blockCheckInShowing)
        try Block.tap(Block.view(BlockCheckInPopup(), h), id: "block.checkin.keep")
        let block = try #require(h.engine.timeBlock)
        #expect(!block.waitingForCalendar)
        #expect(block.nextCheckIn == h.clock.now.addingTimeInterval(2 * 3600))
        #expect(!h.engine.blockCheckInShowing)
        #expect(h.presenter.calls.last == .closeBlockCheckIn)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func endNowEndsAndSavesTheBlock() throws {
        let h = Block.checkIn()
        try Block.tap(Block.view(BlockCheckInPopup(), h), id: "block.checkin.end")
        #expect(h.engine.timeBlock == nil)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.saved.first?.end == h.clock.now)
        #expect(!h.engine.blockCheckInShowing)
    }
}
