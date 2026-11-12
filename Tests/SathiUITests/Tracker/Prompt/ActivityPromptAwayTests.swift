import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt away toggle")
struct ActivityPromptAwayTests {
    private func ask(_ calls: PromptCalls = PromptCalls(), places: [String] = ["Sleep"]) -> TrackerPromptState {
        Prompt.state(.whatNow, calls: calls) { $0.places = places }
    }

    private func chips(_ view: InspectableView<some BaseViewType>) -> [String] {
        Prompt.ids(view, prefix: "tracker.away.").filter { $0 != "tracker.away.toggle" }
    }

    private func toggle(_ view: InspectableView<some BaseViewType>) throws {
        try view.find(viewWithAccessibilityIdentifier: "tracker.away.toggle").find(ViewType.Button.self).tap()
    }

    private func rowLabels() -> [String] {
        [Copywriter.trackerFor, Copywriter.trackerAskMe, Copywriter.trackerCalendar, Copywriter.activityPromptQuiet]
    }

    @Test(arguments: [PromptKind.whatNow, .center, .stillOnIt])
    func theToggleIsOffByDefaultAndShowsNoPlaces(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        #expect(Prompt.has(sut, "tracker.away.toggle"))
        #expect(Prompt.hasText(sut, "I am going away"))
        #expect(chips(sut).isEmpty)
        #expect(ActivityPromptModel(Reasons.withKeep(kind)).awayOn == false)
    }

    @Test func theEventScreenHasNoAwayRow() throws {
        let sut = try Prompt.view(Reasons.withKeep(.eventAsk))
        #expect(!Prompt.has(sut, "tracker.away.toggle"))
        #expect(!Prompt.hasText(sut, "I am going away"))
    }

    @Test func turningItOnShowsTheBuiltInsTheUserPlacesOtherAndAdd() throws {
        let s = ask()
        let model = ActivityPromptModel(s)
        try toggle(Prompt.view(s, model: model))
        #expect(model.awayOn)
        let sut = try Prompt.view(s, model: model)
        #expect(chips(sut) == [
            "tracker.away.place.lunch", "tracker.away.place.meeting", "tracker.away.place.walk", "tracker.away.place.commute",
            "tracker.away.custom.Sleep", "tracker.away.place.other", "tracker.away.add"
        ])
        #expect(Prompt.hasText(sut, "+ Place"))
        for label in rowLabels() {
            #expect(Prompt.hasText(sut, label))
        }
    }

    @Test func aUserPlacePickHidesTheFourRowsAndTheButtonGoesAway() throws {
        let calls = PromptCalls()
        let s = ask(calls)
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.away.custom.Sleep")
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.boxIsOn(sut, "tracker.away.custom.Sleep"))
        #expect(try !Prompt.boxIsOn(sut, "tracker.away.place.other"))
        for label in rowLabels() {
            #expect(!Prompt.hasText(sut, label))
        }
        #expect(try Prompt.buttonText(sut, "tracker.start") == ["Go away · Sleep"])
        #expect(try sut.find(viewWithAccessibilityIdentifier: "prompt.field").isDisabled())
        try Prompt.tap(sut, "tracker.start")
        #expect(calls.wentAway == [AwayPlan(place: .other, name: "Sleep")])
        #expect(calls.started.isEmpty)
    }

    @Test func aBuiltInPickSendsThePlaceWithNoName() throws {
        let calls = PromptCalls()
        let s = ask(calls)
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.away.place.walk")
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.buttonText(sut, "tracker.start") == ["Go away · Walk"])
        try Prompt.tap(sut, "tracker.start")
        #expect(calls.wentAway == [AwayPlan(place: .walk, name: nil)])
    }

    @Test func returnWithAPickGoesAwayOnceAndDoesNotStart() {
        let calls = PromptCalls()
        let s = ask(calls)
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        model.pickAway(.lunch)
        let commands = PromptCommands(state: s, screen: ActivityPromptBuilder.screen(s), model: model)
        commands.start()
        commands.start()
        #expect(calls.wentAway == [AwayPlan(place: .lunch, name: nil)])
        #expect(calls.started.isEmpty)
    }

    @Test func returnWithTheToggleOnAndNoPickStartsTheActivity() {
        let calls = PromptCalls()
        let s = ask(calls)
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        PromptCommands(state: s, screen: ActivityPromptBuilder.screen(s), model: model).start()
        #expect(calls.wentAway.isEmpty)
        #expect(calls.started.map(\.0.text) == ["Write spec"])
    }

    @Test func turningItOffClearsThePickAndBringsTheRowsBack() throws {
        let s = ask()
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        model.pickAway(named: "Sleep")
        try toggle(Prompt.view(s, model: model))
        #expect(model.awayOn == false)
        #expect(model.awayPick == nil)
        let sut = try Prompt.view(s, model: model)
        #expect(chips(sut).isEmpty)
        for label in rowLabels() {
            #expect(Prompt.hasText(sut, label))
        }
        #expect(try Prompt.buttonText(sut, "tracker.start") == [ActivityPromptBuilder.screen(s).startLabel])
    }

    @Test func addOpensAFieldAndSaveAddsAndPicksThePlace() throws {
        let calls = PromptCalls()
        let s = ask(calls)
        let model = ActivityPromptModel(s)
        model.turnAway(true)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.away.add")
        model.awayNewName = " Doctor "
        try Prompt.tap(Prompt.view(s, model: model), "tracker.away.save")
        #expect(calls.addedPlaces == ["Doctor"])
        #expect(model.awayPick == PromptAwayPick(place: .other, name: "Doctor"))
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.boxIsOn(sut, "tracker.away.custom.Doctor"))
        #expect(!Prompt.has(sut, "tracker.away.save"))
    }
}
