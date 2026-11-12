import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt where boxes")
struct ActivityPromptWhereTests {
    private func back(_ calls: PromptCalls = PromptCalls(), places: [String] = [], logged: [Activity] = []) -> TrackerPromptState {
        Prompt.state(.welcomeBack, calls: calls) {
            $0.away = AwaySpan(start: Prompt.now.addingTimeInterval(-2100), end: Prompt.now, cause: .locked)
            $0.places = places
            $0.loggedWhileAway = logged
        }
    }

    @Test(arguments: [PromptKind.whatNow, .center, .stillOnIt, .eventAsk])
    func onlyBackHasWhereBoxes(_ kind: PromptKind) throws {
        let sut = try Prompt.view(Reasons.withKeep(kind))
        #expect(Prompt.ids(sut, prefix: "tracker.place.").isEmpty)
        #expect(!Prompt.hasText(sut, "Where were you?"))
    }

    @Test func backShowsTheBuiltInPlacesThenTheUserPlacesThenAdd() throws {
        let sut = try Prompt.view(back(places: ["Gym"]))
        #expect(Prompt.hasText(sut, "Where were you?"))
        let ids = Prompt.ids(sut, prefix: "tracker.place.")
        #expect(ids == AwayPlace.choices.map { "tracker.place." + $0.rawValue } + ["tracker.place.custom.Gym", "tracker.place.add"])
        #expect(Prompt.hasText(sut, "+ Place"))
        #expect(!Prompt.hasText(sut, "Break"))
    }

    @Test func carryKeepsTheAwayPickWhenTheNewScreenAllowsIt() {
        let old = ActivityPromptModel(Reasons.withKeep(.whatNow))
        old.turnAway(true)
        old.pickAway(named: "Gym")
        let new = ActivityPromptModel(Reasons.withKeep(.center))
        new.carry(from: old)
        #expect(new.awayOn)
        #expect(new.awayPick == PromptAwayPick(place: .other, name: "Gym"))
    }

    @Test func carryDropsTheAwayPickWhenTheNewScreenHasNoAway() {
        let old = ActivityPromptModel(Reasons.withKeep(.whatNow))
        old.turnAway(true)
        old.pickAway(.walk)
        let new = ActivityPromptModel(back())
        new.carry(from: old)
        #expect(!new.awayOn)
        #expect(new.awayPick == nil)
    }

    @Test func aTapSavesThePlaceAtOnceAndFillsTheBox() throws {
        let calls = PromptCalls()
        let s = back(calls)
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.place.walk")
        #expect(calls.places == [.walk])
        #expect(try Prompt.boxIsOn(Prompt.view(s, model: model), "tracker.place.walk"))
    }

    @Test func aUserPlaceTapSavesItsName() throws {
        let calls = PromptCalls()
        let s = back(calls, places: ["Gym"])
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.place.custom.Gym")
        #expect(calls.placeNames == ["Gym"])
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.boxIsOn(sut, "tracker.place.custom.Gym"))
        #expect(try !Prompt.boxIsOn(sut, "tracker.place.other"))
    }

    @Test func addOpensAFieldAndSaveAddsThePlace() throws {
        let calls = PromptCalls()
        let s = back(calls)
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "tracker.place.add")
        model.places.newName = " Doctor "
        try Prompt.tap(Prompt.view(s, model: model), "tracker.place.save")
        #expect(calls.addedPlaces == ["Doctor"])
        #expect(model.places.places == ["Doctor"])
        let sut = try Prompt.view(s, model: model)
        #expect(try Prompt.boxIsOn(sut, "tracker.place.custom.Doctor"))
        #expect(!Prompt.has(sut, "tracker.place.save"))
    }

    @Test func noAddBoxWithEightPlaces() throws {
        let sut = try Prompt.view(back(places: (1 ... 8).map { "P\($0)" }))
        #expect(!Prompt.has(sut, "tracker.place.add"))
    }

    @Test func whileAwayEventsHaveNotAttending() throws {
        let calls = PromptCalls()
        let logged = [
            Activity(kind: .event, text: "Standup", start: Prompt.now.addingTimeInterval(-1800), end: Prompt.now, sourceEventID: "e9")
        ]
        let sut = try Prompt.view(back(calls, logged: logged))
        #expect(Prompt.hasText(sut, "Standup"))
        try Prompt.tap(sut, "tracker.notAttending")
        #expect(calls.notAttending == ["e9"])
    }
}
