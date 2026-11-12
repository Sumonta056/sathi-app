import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Still on it redesign")
struct StillOnItRedesignTests {
    private func state(late: Int? = nil) -> TrackerPromptState {
        Prompt.state(.stillOnIt) {
            $0.running = RunningActivity(
                text: "Write spec", category: "Coding", start: Prompt.now.addingTimeInterval(-1800),
                expectedLength: .minutes(30), askAt: Prompt.now
            )
            $0.waitedMinutes = late
        }
    }

    @Test func onTimeEyebrowNamesTheMinutesSoFar() throws {
        let sut = try StillOnItPopup(state: state()).inspect()
        #expect(Prompt.hasText(sut, "STILL ON IT? · 30 MIN SO FAR"))
    }

    @Test func onTimeTitleHasTheCategoryDotAndNoDetailLine() throws {
        let header = try StillOnItPopup(state: state()).inspect().find(TrackerHeader.self).actualView()
        #expect(header.title == "Write spec")
        #expect(header.dot == 0x4CC3F5)
        #expect(header.detail == nil)
    }

    @Test func onTimeSaysOrMoreBeforeTheLaterChips() throws {
        let sut = try StillOnItPopup(state: state()).inspect()
        #expect(Prompt.hasText(sut, "Or more"))
        #expect(!Prompt.hasText(sut, "or ask in"))
        #expect(Prompt.has(sut, "tracker.in.5"))
        #expect(Prompt.has(sut, "tracker.in.30"))
    }

    @Test func onTimeDoneSaysPickWhenYouSwitched() throws {
        let sut = try StillOnItPopup(state: state()).inspect()
        #expect(Prompt.hasText(sut, "Done · pick when you switched"))
        #expect(!Prompt.hasText(sut, "Done"))
        #expect(Prompt.ids(sut, prefix: "tracker.").filter { $0 == "tracker.done" || $0 == "tracker.skip" } == ["tracker.done", "tracker.skip"])
    }

    @Test func lateKeepsTheAskedEyebrowAndTheDetailLine() throws {
        let sut = try StillOnItPopup(state: state(late: 7)).inspect()
        let eyebrow = Copywriter.trackerStillOnEyebrow(Prompt.now, late: true, calendar: Prompt.calendar)
        #expect(Prompt.hasText(sut, eyebrow))
        #expect(!Prompt.texts(sut).contains { $0.hasSuffix("MIN SO FAR") })
        #expect(try sut.find(TrackerHeader.self).actualView().detail != nil)
        #expect(Prompt.hasText(sut, "This question waited 7 min."))
    }
}

@MainActor
@Suite("Welcome back redesign")
struct WelcomeBackRedesignTests {
    private let start = Prompt.now.addingTimeInterval(-45 * 60)

    private func state(cause: AwayCause = .locked) -> TrackerPromptState {
        Prompt.state(.welcomeBack) {
            $0.lastActivity = ActivityDraft(text: "Coding")
            $0.away = AwaySpan(start: start, end: Prompt.now, cause: cause)
        }
    }

    @Test func theEyebrowHasTheSpanThenTheLength() throws {
        let sut = try WelcomeBackView(state: state()).inspect()
        let span = Copywriter.trackerSpan(start, Prompt.now, calendar: Prompt.calendar)
        #expect(Prompt.hasText(sut, "AWAY " + span + " · 45 MIN"))
        #expect(Prompt.hasText(sut, "Welcome back. Where were you?"))
    }

    @Test func somethingNewAndIWasHereShareOneRowAfterIdle() throws {
        let sut = try WelcomeBackView(state: state(cause: .idle)).inspect()
        let rows = sut.findAll(ViewType.HStack.self).filter {
            Prompt.has($0, "tracker.new") && Prompt.has($0, "tracker.here") && !Prompt.has($0, "tracker.back")
        }
        #expect(!rows.isEmpty)
        #expect(Prompt.ids(sut, prefix: "tracker.").filter { ["tracker.back", "tracker.new", "tracker.here"].contains($0) }
            == ["tracker.back", "tracker.new", "tracker.here"])
    }

    @Test func whereWereYouIsAStepAndIsNotMarkedOptional() throws {
        let sut = try WelcomeBackView(state: state()).inspect()
        #expect(Prompt.hasText(sut, "Where were you?"))
        #expect(!Prompt.texts(sut).contains { $0.localizedCaseInsensitiveContains("optional") })
        for place in AwayPlace.choices {
            #expect(Prompt.has(sut, "tracker.place." + place.rawValue))
        }
    }

    @Test func theKeyHintNamesContinueAndEsc() throws {
        let sut = try WelcomeBackView(state: state()).inspect()
        #expect(Prompt.hasText(sut, "↵ continue · esc keep as Away"))
    }
}
