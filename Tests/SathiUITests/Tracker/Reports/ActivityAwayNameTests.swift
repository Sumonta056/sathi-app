import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity away name")
struct ActivityAwayNameTests {
    typealias Fix = ActivityViewSupport

    private static let named = Activity(
        kind: .away, text: "Away · Doctor", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: .other, awayPlaceName: "Doctor"
    )
    private static let other = Activity(kind: .away, text: "Away · Other", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: .other)
    private static let stale = Activity(kind: .away, text: "Away", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: .walk)

    private func form(_ a: Activity, saved: @escaping (ActivityEdit) -> Void = { _ in }) -> ActivityEditSection {
        ActivityEditSection(
            draft: ActivityEditDraft(a, calendar: Fix.calendar), title: "Edit activity", accent: Night.chipText,
            categories: ActivityCategory.defaults, calendars: [], dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar,
            save: { saved($0); return .saved(a.id) }, delete: {}, close: {}
        )
    }

    private func chips(_ a: Activity) throws -> [PromptBox] {
        try form(a).inspect().findAll(PromptBox.self).compactMap { try? $0.actualView() }.filter { $0.id.hasPrefix("report.place.") }
    }

    private func row(_ a: Activity) -> ActivityTimelineRow {
        ActivityTimelineRow(activity: a, categories: ActivityCategory.defaults, calendar: Fix.calendar)
    }

    @Test func theDraftCarriesTheNameIntoTheEdit() {
        let d = ActivityEditDraft(Self.named, calendar: Fix.calendar)
        #expect(d.awayPlaceName == "Doctor")
        let e = d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(e.awayPlace == .other)
        #expect(e.awayPlaceName == "Doctor")
    }

    @Test func aDraftWithoutANameSendsNoName() {
        let d = ActivityEditDraft(Self.other, calendar: Fix.calendar)
        #expect(d.awayPlaceName == nil)
        #expect(d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar).awayPlaceName == nil)
    }

    @Test func aDraftThatDropsItsNameSendsNoName() {
        var d = ActivityEditDraft(Self.named, calendar: Fix.calendar)
        d.awayPlace = .lunch
        d.awayPlaceName = nil
        let e = d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(e.awayPlace == .lunch)
        #expect(e.awayPlaceName == nil)
    }

    @Test func theOtherChipShowsTheSavedName() throws {
        let chip = try #require(try chips(Self.named).first { $0.id == "report.place.other" })
        #expect(chip.label == "Doctor")
        #expect(chip.on)
    }

    @Test func theOtherChipSaysOtherWithoutAName() throws {
        let chip = try #require(try chips(Self.other).first { $0.id == "report.place.other" })
        #expect(chip.label == "Other")
        #expect(chip.on)
    }

    @Test func theBuiltInChipsKeepTheirLabelsNextToANamedOther() throws {
        let labels = try chips(Self.named).map(\.label)
        #expect(labels == ["Lunch", "Meeting", "Walk", "Commute", "Doctor", "Break"])
    }

    @Test func saveOfAnUntouchedNamedAwaySendsTheName() throws {
        var edit: ActivityEdit?
        let sut = form(Self.named) { edit = $0 }
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: "Save") != nil }.tap()
        #expect(edit?.awayPlace == .other)
        #expect(edit?.awayPlaceName == "Doctor")
    }

    @Test func theLogRowShowsTheNamedAwayText() throws {
        let sut = try row(Self.named).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Away · Doctor") }
        #expect(Find.lacks(sut, text: "Away · Other"))
    }

    @Test func theLogRowShowsThePlaceWithoutAName() throws {
        #expect(throws: Never.self) { try row(Self.other).inspect().find(text: "Away · Other") }
    }

    @Test func theLogRowBuildsItsTextFromThePlaceAndNotFromTheStoredText() throws {
        #expect(throws: Never.self) { try row(Self.stale).inspect().find(text: "Away · Walk") }
    }
}
