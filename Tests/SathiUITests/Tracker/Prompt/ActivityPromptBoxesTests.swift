import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt boxes")
struct ActivityPromptBoxesTests {
    @Test(arguments: PromptKind.allCases)
    func noDropdownAnywhere(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        #expect(sut.findAll(ViewType.Menu.self).isEmpty)
        #expect(sut.findAll(ViewType.Picker.self).isEmpty)
        #expect(sut.findAll(TrackerCategoryMenu.self).isEmpty)
    }

    @Test func everyCategoryIsABoxAndATapPicksIt() throws {
        let s = Prompt.state(.whatNow)
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        for c in ActivityCategory.defaults {
            #expect(Prompt.has(sut, "tracker.category." + c.name))
        }
        try Prompt.tap(sut, "tracker.category.Review")
        #expect(model.draft.category == "Review")
        #expect(try Prompt.boxIsOn(Prompt.view(s, model: model), "tracker.category.Review"))
    }

    @Test func aTapOnTheSelectedCategoryClearsIt() throws {
        let s = Prompt.state(.whatNow)
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.category.Coding")
        #expect(model.draft.category == nil)
    }

    @Test(arguments: ActivityLength.choices)
    func everyLengthIsABox(_ length: ActivityLength) throws {
        let s = Prompt.state(.whatNow)
        let model = ActivityPromptModel(s)
        let label = Copywriter.trackerLengthLabel(length)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.for." + label)
        #expect(model.draft.length == length)
        #expect(try Prompt.boxIsOn(Prompt.view(s, model: model), "tracker.for." + label))
    }

    @Test(arguments: Limits.askOffsets)
    func everyAskOffsetIsABox(_ offset: Int) throws {
        let s = Prompt.state(.whatNow) { $0.draft.askOffsetMinutes = 99 }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.ask.\(offset)")
        #expect(model.draft.askOffsetMinutes == offset)
    }

    @Test func theAskBoxesSayWhenItEndsAndPlusMinutes() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        for label in ["When it ends", "+5 min", "+15 min"] {
            #expect(Prompt.hasText(sut, label))
        }
    }

    @Test func theEventLengthIsUntilItsEndOnly() throws {
        let s = Reasons.withKeep(.eventAsk)
        let sut = try Prompt.view(s)
        #expect(Prompt.ids(sut, prefix: "tracker.for.").isEmpty)
        #expect(Prompt.hasText(sut, Copywriter.activityPromptUntil(Prompt.event().end, calendar: Prompt.calendar)))
    }

    @Test func theQuietSwitchIsOffAndDisabledForOpen() throws {
        let s = Prompt.state(.whatNow) {
            $0.draft.length = .open
            $0.draft.quiet = true
        }
        let sut = try Prompt.view(s)
        let quiet = try sut.find(BuddySwitch.self)
        #expect(try !quiet.actualView().isOn)
        #expect(try quiet.find(ViewType.Button.self).isDisabled())
    }

    @Test func theQuietSwitchTurnsOnForALength() throws {
        let s = Prompt.state(.whatNow) { $0.draft.length = .minutes(30) }
        let model = ActivityPromptModel(s)
        try Prompt.view(s, model: model).find(BuddySwitch.self).find(ViewType.Button.self).tap()
        #expect(model.draft.quiet)
    }

    @Test func openingAfterQuietTurnsQuietOff() throws {
        let s = Prompt.state(.whatNow) {
            $0.draft.length = .minutes(30)
            $0.draft.quiet = true
        }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.for.Open")
        #expect(!model.draft.quiet)
    }

    @Test func theRowsAreNamed() throws {
        let sut = try Prompt.view(Prompt.state(.whatNow))
        for label in ["Category", "For", "Ask me", "Calendar", "Quiet"] {
            #expect(Prompt.hasText(sut, label))
        }
    }

    @Test func theEventHasNoAskMeAndNoQuietRowAndAFixedField() throws {
        let sut = try Prompt.view(Reasons.withKeep(.eventAsk))
        #expect(!Prompt.hasText(sut, "Ask me"))
        #expect(!Prompt.hasText(sut, "Quiet"))
        #expect(sut.findAll(BuddySwitch.self).isEmpty)
        #expect(try sut.find(LazyTextField.self).isDisabled())
    }

    @Test(arguments: [PromptKind.whatNow, .center, .stillOnIt, .welcomeBack])
    func theOtherReasonsShowAskMeAndQuiet(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        #expect(Prompt.hasText(sut, "Ask me"))
        #expect(Prompt.hasText(sut, "Quiet"))
        #expect(sut.findAll(BuddySwitch.self).count == 1)
        #expect(try !sut.find(LazyTextField.self).isDisabled())
    }
}
