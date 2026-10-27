import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Habit card up next")
struct HabitCardUpNextTests {
    private func card(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(HabitCard(id: id), h).inspect()
    }

    @Test func readingCardShowsUpNextWithAPick() throws {
        let h = Books.harness([Books.alpha, Books.beta])
        #expect(try card(.reading, h).find(text: "Up next: Alpha") != nil)
    }

    @Test func readingCardHasNoUpNextWithoutAPick() throws {
        let h = Books.harness([Books.old])
        #expect(try !MenuFind.hasText(card(.reading, h), containing: "Up next"))
    }

    @Test func readingCardHasNoUpNextWithAnEmptyList() throws {
        let h = Books.harness([])
        #expect(try !MenuFind.hasText(card(.reading, h), containing: "Up next"))
    }

    @Test func upNextLineIsOneLine() throws {
        let h = Books.harness([Books.alpha])
        #expect(try card(.reading, h).find(text: "Up next: Alpha").lineLimit() == 1)
    }

    @Test func tappingUpNextOpensTheLinkAndStartsTheSession() throws {
        let h = Books.harness([Books.alpha, Books.beta])
        try Find.button(card(.reading, h), holding: "Up next: Alpha").tap()
        #expect(h.links.opened == [Books.alpha.url])
        #expect(h.engine.phase(.reading) == .session)
    }

    @Test(arguments: [HabitID.water, .meditation, .gym])
    func otherCardsNeverShowUpNext(_ id: HabitID) throws {
        let h = EngineHarness {
            $0.prefs.reading.list = [Books.alpha]
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
        }
        #expect(try !MenuFind.hasText(card(id, h), containing: "Up next"))
    }

    @Test func upNextIsHiddenWhileAReadingSessionRuns() throws {
        let h = Books.harness([Books.alpha, Books.beta])
        h.engine.startReading()
        #expect(try !MenuFind.hasText(card(.reading, h), containing: "Up next"))
    }

    @Test func upNextSitsBelowTheGoalLine() throws {
        let h = Books.harness([Books.alpha])
        let texts = try card(.reading, h).findAll(ViewType.Text.self).map { try $0.string() }
        let goal = try #require(texts.firstIndex { $0.contains("min") })
        let next = try #require(texts.firstIndex { $0.contains("Up next") })
        #expect(next > goal)
    }
}
