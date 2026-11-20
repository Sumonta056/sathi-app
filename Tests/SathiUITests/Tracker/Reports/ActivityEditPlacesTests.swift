import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edit places")
struct ActivityEditPlacesTests {
    typealias Fix = ActivityViewSupport

    private final class Box {
        var draft: ActivityEditDraft
        init(_ draft: ActivityEditDraft) { self.draft = draft }
    }

    private static func away(_ place: AwayPlace?, name: String? = nil) -> Activity {
        Activity(kind: .away, text: "Away", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: place, awayPlaceName: name)
    }

    private func places(_ box: Box, _ names: [String]) -> ActivityEditPlaces {
        ActivityEditPlaces(draft: Binding(get: { box.draft }, set: { box.draft = $0 }), places: names)
    }

    private func chips(_ box: Box, _ names: [String]) throws -> [PromptBox] {
        try places(box, names).inspect().findAll(PromptBox.self).compactMap { try? $0.actualView() }
            .filter { $0.id.hasPrefix("report.place.") }
    }

    @Test func theChipsMatchThePopupWithTheUserPlacesBeforeOther() throws {
        let box = Box(ActivityEditDraft(Self.away(.walk), calendar: Fix.calendar))
        let ids = try chips(box, ["Gym hall", "Doctor"]).map(\.id)
        #expect(ids == [
            "report.place.lunch", "report.place.meeting", "report.place.walk", "report.place.commute",
            "report.place.custom.Gym hall", "report.place.custom.Doctor", "report.place.other"
        ])
    }

    @Test func aUserPlaceChipShowsItsName() throws {
        let box = Box(ActivityEditDraft(Self.away(.walk), calendar: Fix.calendar))
        let chip = try #require(try chips(box, ["Gym hall"]).first { $0.id == "report.place.custom.Gym hall" })
        #expect(chip.label == "Gym hall")
        #expect(!chip.on)
    }

    @Test func breakShowsOnlyOnARowThatHasIt() throws {
        let walk = Box(ActivityEditDraft(Self.away(.walk), calendar: Fix.calendar))
        #expect(try !chips(walk, []).map(\.id).contains("report.place.break"))
        let pause = Box(ActivityEditDraft(Self.away(.breakTime), calendar: Fix.calendar))
        let chip = try #require(try chips(pause, []).first { $0.id == "report.place.break" })
        #expect(chip.on)
    }

    @Test func aRowWithNoPlaceHasNoBreakChip() throws {
        let box = Box(ActivityEditDraft(Self.away(nil), calendar: Fix.calendar))
        #expect(try !chips(box, []).map(\.id).contains("report.place.break"))
    }

    @Test func tappingAUserPlacePicksOtherWithTheName() throws {
        let box = Box(ActivityEditDraft(Self.away(.walk), calendar: Fix.calendar))
        let chip = try #require(try chips(box, ["Gym hall"]).first { $0.id == "report.place.custom.Gym hall" })
        chip.action()
        #expect(box.draft.awayPlace == .other)
        #expect(box.draft.awayPlaceName == "Gym hall")
    }

    @Test func tappingABuiltInPlaceClearsTheName() throws {
        let box = Box(ActivityEditDraft(Self.away(.other, name: "Gym hall"), calendar: Fix.calendar))
        let chip = try #require(try chips(box, ["Gym hall"]).first { $0.id == "report.place.lunch" })
        chip.action()
        #expect(box.draft.awayPlace == .lunch)
        #expect(box.draft.awayPlaceName == nil)
    }
}
