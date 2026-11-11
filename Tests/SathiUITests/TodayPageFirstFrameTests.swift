import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Today page first frame")
struct TodayPageFirstFrameTests {
    private let cal = Calendar(identifier: .gregorian)

    @Test func idleWithoutNextAskShowsNoAskLine() throws {
        let sut = try hosted(TodayNowCard(now: .idle(nextAsk: nil), calendar: cal), EngineHarness.tracker()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Not tracking now") }
        #expect(Find.lacks(sut, text: "Next ask"))
    }

    @Test func pageShowsTheFirstScreenBeforeAppear() throws {
        let sut = try hosted(TodayPage(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(TodayHeader.self) }
    }
}
