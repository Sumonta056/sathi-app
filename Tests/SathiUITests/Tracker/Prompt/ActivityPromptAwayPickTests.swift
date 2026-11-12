import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt away pick")
struct ActivityPromptAwayPickTests {
    private let earlier = Prompt.now.addingTimeInterval(-1200)

    private func picked(_ s: TrackerPromptState) -> ActivityPromptModel {
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        model.pickAway(named: "Sleep")
        return model
    }

    @Test func welcomeBackHasNoAwayRow() throws {
        let sut = try Prompt.view(Reasons.withKeep(.welcomeBack))
        #expect(!Prompt.has(sut, "tracker.away.toggle"))
        #expect(!Prompt.hasText(sut, Copywriter.activityPromptAwaySwitch))
        #expect(Prompt.ids(sut, prefix: "tracker.away.").isEmpty)
    }

    @Test func welcomeBackIgnoresAPickAndStarts() throws {
        let calls = PromptCalls()
        let s = Reasons.withKeep(.welcomeBack, calls: calls)
        let model = picked(s)
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.buttonText(sut, "tracker.start") == [ActivityPromptBuilder.screen(s).startLabel])
        PromptCommands(state: s, screen: ActivityPromptBuilder.screen(s), model: model).start()
        #expect(calls.wentAway.isEmpty)
        #expect(calls.started.map(\.0.text) == ["Write spec"])
    }

    @Test(arguments: [PromptKind.whatNow, .center, .stillOnIt])
    func aPickHidesKeep(_ kind: PromptKind) throws {
        let s = Reasons.withKeep(kind)
        #expect(try Prompt.has(Prompt.view(s), "prompt.keep"))
        let sut = try Prompt.view(s, model: picked(s))
        #expect(!Prompt.has(sut, "prompt.keep"))
        #expect(Prompt.has(sut, "tracker.skip") || Prompt.has(sut, "tracker.close") || Prompt.has(sut, "tracker.no"))
        #expect(try Prompt.buttonText(sut, "tracker.start") == ["Go away · Sleep"])
    }

    @Test func aPickHidesTheStartedLinkAndBoxes() throws {
        let s = Prompt.state(.whatNow) { $0.switchTimes = [earlier, Prompt.now] }
        let model = ActivityPromptModel(s)
        model.showsStarted = true
        #expect(try Prompt.has(Prompt.view(s, model: model), "prompt.started"))
        model.turnAway(true)
        model.pickAway(.lunch)
        let sut = try Prompt.view(s, model: model)
        #expect(!Prompt.has(sut, "prompt.started"))
        #expect(Prompt.ids(sut, prefix: "prompt.started.").isEmpty)
        #expect(Prompt.hasText(sut, "Esc: Skip"))
    }

    @Test func aPickDisablesTheRecentCards() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(3) }
        let model = picked(s)
        let sut = try Prompt.view(s, model: model)
        let card = try sut.find(viewWithAccessibilityIdentifier: "prompt.recent.1").find(ViewType.Button.self, relation: .parent)
        #expect(card.isDisabled())
        #expect(model.draft.text == "Write spec")
    }

    @Test func theSwitchTextIsHiddenFromVoiceOver() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        let text = try sut.find(text: Copywriter.activityPromptAwaySwitch)
        #expect(try text.accessibilityHidden())
    }
}
