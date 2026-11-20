import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edit away switch")
struct ActivityEditAwaySwitchTests {
    typealias Fix = ActivityViewSupport

    private static let work = Fix.item("Fix login bug", "Coding", 4, (9, 0), (10, 30))
    private static let away = Activity(kind: .away, text: "Away · Walk", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: .walk)
    private static let buddy = Activity(kind: .buddy, text: "Reading", start: Fix.at(4, 14), end: Fix.at(4, 14, 15))
    private static let block = Activity(kind: .timeBlock, text: "Deep work", start: Fix.at(4, 15), end: Fix.at(4, 16))
    private static let event = Activity(
        kind: .event, text: "Standup", start: Fix.at(4, 11), end: Fix.at(4, 11, 30), calendarID: "work", sourceEventID: "m1"
    )
    private static let fromEvent = Activity(
        text: "Planning", start: Fix.at(4, 16), end: Fix.at(4, 16, 30), calendarID: "work", sourceEventID: "m2"
    )

    private var dayStart: Date { Fix.key(4).start(in: Fix.calendar) }

    private func draft(_ a: Activity) -> ActivityEditDraft {
        ActivityEditDraft(a, calendar: Fix.calendar, writable: Fix.calendars.map(\.id))
    }

    private func section(_ d: ActivityEditDraft) -> ActivityEditSection {
        ActivityEditSection(
            draft: d, title: "Edit activity", accent: Night.tracker,
            categories: ActivityCategory.defaults, calendars: Fix.calendars, dayStart: dayStart,
            calendar: Fix.calendar, save: { _ in .saved(ActivityID()) }, delete: nil, close: {}
        )
    }

    private func hasSwitch(_ d: ActivityEditDraft) throws -> Bool {
        (try? section(d).inspect().find(viewWithAccessibilityIdentifier: "activity.away.switch")) != nil
    }

    @Test(arguments: [(work, true), (away, true), (buddy, false), (block, false), (event, false), (fromEvent, false)])
    func canSwitchKindOnlyOnWorkAndAwayRows(_ a: Activity, _ expected: Bool) {
        #expect(draft(a).canSwitchKind == expected)
    }

    @Test func aNewPastActivityCannotSwitchKind() {
        let d = ActivityEditDraft(start: Fix.at(4, 9), end: Fix.at(4, 10), calendar: Fix.calendar)
        #expect(!d.canSwitchKind)
    }

    @Test func anUntouchedDraftKeepsTheKind() {
        #expect(draft(Self.work).edit(dayStart: dayStart, calendar: Fix.calendar).kind == nil)
        #expect(draft(Self.away).edit(dayStart: dayStart, calendar: Fix.calendar).kind == nil)
    }

    @Test func aWorkDraftSwitchedToAwaySendsAwayAndHidesTheCalendar() {
        var d = draft(Self.work)
        d.setAway(true)
        d.pickPlace(.lunch)
        #expect(d.isAway)
        #expect(!d.showsCalendar)
        let e = d.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(e.kind == .away)
        #expect(e.awayPlace == .lunch)
    }

    @Test func aWorkDraftSwitchedToAwayAndBackKeepsTheKind() {
        var d = draft(Self.work)
        d.setAway(true)
        d.setAway(false)
        #expect(!d.isAway)
        #expect(d.showsCalendar)
        #expect(d.edit(dayStart: dayStart, calendar: Fix.calendar).kind == nil)
    }

    @Test func anAwayDraftSwitchedToWorkSendsWorkAndThePickedCalendar() {
        var d = draft(Self.away)
        d.setAway(false)
        d.text = "Sleep"
        d.category = "Break"
        d.pickCalendar("home")
        #expect(!d.isAway)
        #expect(d.showsCalendar)
        let e = d.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(e.kind == .work)
        #expect(e.text == "Sleep")
        #expect(e.category == "Break")
        #expect(e.calendar == .calendar("home"))
    }

    @Test func pickingAUserPlaceStoresOtherWithTheName() {
        var d = draft(Self.away)
        d.pickPlace(named: "Gym hall")
        #expect(d.awayPlace == .other)
        #expect(d.awayPlaceName == "Gym hall")
        let e = d.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(e.awayPlace == .other)
        #expect(e.awayPlaceName == "Gym hall")
    }

    @Test func pickingABuiltInPlaceClearsTheName() {
        var d = draft(Self.away)
        d.pickPlace(named: "Gym hall")
        d.pickPlace(.meeting)
        #expect(d.awayPlace == .meeting)
        #expect(d.awayPlaceName == nil)
    }

    @Test(arguments: [(work, true), (away, true), (buddy, false), (block, false), (event, false), (fromEvent, false)])
    func theSectionShowsTheSwitchOnlyWhenTheKindCanSwitch(_ a: Activity, _ shows: Bool) throws {
        #expect(try hasSwitch(draft(a)) == shows)
    }

    @Test func theAddSectionHasNoSwitch() throws {
        let d = ActivityEditDraft(start: Fix.at(4, 9), end: Fix.at(4, 10), calendar: Fix.calendar)
        #expect(try !hasSwitch(d))
    }

    @Test func aWorkDraftSwitchedToAwayShowsPlacesWithoutCalendar() throws {
        var d = draft(Self.work)
        d.setAway(true)
        let v = try section(d).inspect()
        #expect(throws: Never.self) { try v.find(viewWithAccessibilityIdentifier: "report.place.lunch") }
        #expect(v.findAll(PromptBox.self).compactMap { try? $0.actualView() }.filter { $0.id.hasPrefix("activity.calendar.") }.isEmpty)
        #expect(throws: (any Error).self) { try v.find(LazyTextField.self) }
    }
}
