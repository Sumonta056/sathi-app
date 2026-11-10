import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("What now popup after Done")
struct WhatNowSwitchTests {
    private func times(_ n: Int) -> [Date] {
        (0 ..< n).map { Prompt.now.addingTimeInterval(Double($0 - n + 1) * 5 * 60) }
    }

    private func doneState(_ n: Int, calls: PromptCalls = PromptCalls()) -> TrackerPromptState {
        Prompt.state(.whatNow, calls: calls) {
            $0.switchTimes = times(n)
            $0.lastActivity = ActivityDraft(text: "Coding")
        }
    }

    @Test func noRowWithoutSwitchTimes() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(!Prompt.has(sut, "tracker.switch.chip"))
        #expect((try? sut.find(text: "Started")) == nil)
    }

    @Test func fewChipsShowChipsWithNowLast() throws {
        let sut = try WhatNowPopup(state: doneState(3)).inspect()
        #expect(sut.findAll(TrackerChip.self).filter { (try? $0.actualView().id) == "tracker.switch.chip" }.count == 3)
        #expect(throws: Never.self) { try sut.find(text: "Now") }
        #expect(sut.findAll(TimeMenu.self).isEmpty)
    }

    @Test func moreThanFourChipsShowTheGrid() throws {
        let sut = try WhatNowPopup(state: doneState(Limits.switchChipsBeforeGrid + 1)).inspect()
        #expect(sut.findAll(TimeMenu.self).count == 1)
        #expect(!Prompt.has(sut, "tracker.switch.chip"))
    }

    @Test func startPassesNowAsTheDefaultSwitchTime() throws {
        let calls = PromptCalls()
        try Prompt.tap(WhatNowPopup(state: doneState(3, calls: calls)).inspect(), "tracker.start")
        #expect(calls.started.first?.1 == Prompt.now)
    }

    @Test func skipEndsTheOldActivityAtTheSwitchTime() throws {
        let calls = PromptCalls()
        try Prompt.tap(WhatNowPopup(state: doneState(3, calls: calls)).inspect(), "tracker.skip")
        #expect(calls.skipped.map { $0 == Prompt.now } == [true])
    }

    @Test func eyebrowNamesTheFinishedActivity() throws {
        let sut = try WhatNowPopup(state: doneState(3)).inspect()
        let eyebrow = Copywriter.trackerDoneEyebrow("Coding", Prompt.now, calendar: Prompt.calendar)
        #expect(throws: Never.self) { try sut.find(text: eyebrow) }
    }

    @Test func continueButtonShowsAndContinuesFromNow() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.switchTimes = times(3)
            $0.resume = ActivityDraft(text: "Coding")
        }
        let sut = try WhatNowPopup(state: s).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Continue Coding") }
        try Prompt.tap(sut, "tracker.continue")
        #expect(calls.continued.first == Prompt.now)
    }

    @Test func noContinueButtonWithoutResume() throws {
        let sut = try WhatNowPopup(state: doneState(3)).inspect()
        #expect(!Prompt.has(sut, "tracker.continue"))
    }

    @Test func switchPickMapsGridMinutesToNearestTime() {
        let ts = times(6)
        let target = TrackerSwitchPick.minutes(of: ts[2], calendar: Prompt.calendar)
        #expect(TrackerSwitchPick.nearest(to: target, in: ts, calendar: Prompt.calendar) == ts[2])
        #expect(TrackerSwitchPick.nearest(to: target + 1, in: ts, calendar: Prompt.calendar) == ts[2])
    }
}
