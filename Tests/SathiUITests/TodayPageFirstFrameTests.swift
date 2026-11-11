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
        let h = EngineHarness.tracker()
        let sut = try hosted(TodayNowCard(e: h.engine, now: .idle(nextAsk: nil), calendar: cal), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Not tracking now") }
        #expect(Find.lacks(sut, text: "Next ask"))
    }

    @Test func pageShowsTheFirstScreenBeforeAppear() throws {
        let sut = try hosted(TodayPage(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(TodayHeader.self) }
    }

    @Test func onlyARunningNowCardIsRed() throws {
        let h = EngineHarness.tracker()
        func fill(_ now: TodayNow) throws -> Color {
            try hosted(TodayNowCard(e: h.engine, now: now, calendar: cal), h).inspect()
                .find(ViewType.HStack.self).background().shape().fillShapeStyle(Color.self)
        }
        #expect(try fill(.running(minutes: 1, text: "A", category: nil, since: day(2026, 3, 4, 9), nextAsk: nil)) == Night.trackerFill)
        #expect(try fill(.idle(nextAsk: nil)) == Night.card)
        #expect(try fill(.off) == Night.card)
    }
}
