import AppKit
@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt back fit")
struct ActivityPromptBackFitTests {
    private let rowWidth = BackFit.rowWidth

    private func prompt(_ s: TrackerPromptState) -> NSView {
        BackFit.host(ActivityPromptView(state: s, model: nil))
    }

    private func row(_ s: TrackerPromptState) -> NSView {
        let boxes = PromptCalendarBoxes(model: ActivityPromptModel(s), state: s, screen: ActivityPromptBuilder.screen(s))
            .frame(width: rowWidth)
        return BackFit.host(boxes)
    }

    private func rowHeight(_ s: TrackerPromptState) -> CGFloat {
        row(s).fittingSize.height
    }

    private func moreLabels(_ s: TrackerPromptState) throws -> [String] {
        let sut = try Prompt.view(s)
        return sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "prompt.calendar.more" })
            .compactMap { try? $0.find(ViewType.Button.self, relation: .parent) }
            .flatMap { Prompt.texts($0) }
    }

    @Test func theFullWelcomeBackFitsWithNoScroll() {
        let s = BackFit.state()
        #expect(ActivityPromptBuilder.screen(s).card != nil)
        #expect(s.places.allSatisfy { $0.count <= Limits.awayPlaceNameMax })
        #expect(s.categories.count == Limits.categoryMax)
        #expect(!BackFit.hasScroll(prompt(s)))
    }

    @Test func longCalendarNamesDrawFewerThanFiveChipsInListOrder() {
        let drawn = BackFit.drawnCalendars(row(BackFit.state()))
        #expect(!drawn.isEmpty)
        #expect(drawn.count < Limits.promptCalendarsShown)
        #expect(drawn == Set((0 ..< drawn.count).map { "c\($0 + 1)" }))
    }

    @Test func moreCountsEveryCalendarWithoutAChip() throws {
        let s = BackFit.state()
        let drawn = BackFit.drawnCalendars(row(s))
        let hidden = BackFit.calendars.count - drawn.count
        #expect(drawn.count < Limits.promptCalendarsShown)
        #expect(try moreLabels(s).contains(Copywriter.activityPromptCalendarMore(hidden)))
    }

    @Test func theCalendarRowNeverWraps() {
        let one = Prompt.state(.welcomeBack) {
            $0.calendars = [CalendarChoice(id: "w", title: "Work", account: "iCloud", colorHex: 0x4CC3F5)]
        }
        #expect(rowHeight(BackFit.state()) == rowHeight(one))
    }

    @Test func aPickedCalendarPastTheRowKeepsItsChip() throws {
        let s = BackFit.state(picked: "c15")
        let drawn = BackFit.drawnCalendars(row(s))
        #expect(drawn.contains("c15"))
        #expect(drawn.count < Limits.promptCalendarsShown)
        #expect(drawn.subtracting(["c15"]) == Set((0 ..< drawn.count - 1).map { "c\($0 + 1)" }))
        #expect(try Prompt.boxIsOn(Prompt.view(s), "prompt.calendar.c15"))
    }

    @Test func aPickedCalendarRowNeverWraps() {
        let one = Prompt.state(.welcomeBack) {
            $0.calendars = [CalendarChoice(id: "w", title: BackFit.titles[14], account: "iCloud", colorHex: 0x4CC3F5)]
            $0.draft.calendarID = "w"
        }
        #expect(rowHeight(BackFit.state(picked: "c15")) == rowHeight(one))
    }

    @Test func sixteenLongCategoriesScrollWithNoScrollBarAndShowEveryCategory() throws {
        var s = BackFit.state()
        s.categories = BackFit.longCategories
        #expect(s.categories.count == Limits.categoryMax)
        let scroll = try #require(BackFit.scrollView(prompt(s)))
        #expect(BackFit.scrollBarHidden(scroll))
        let ids = try Prompt.view(s).findAll(where: { (try? $0.accessibilityIdentifier())?.hasPrefix("tracker.category.") == true })
            .compactMap { try? $0.accessibilityIdentifier() }
        #expect(Set(ids) == Set(s.categories.map { "tracker.category." + $0.name }))
    }
}
