import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading pick views")
struct ReadingPickViewTests {
    private let alpha = Books.alpha
    private let beta = Books.beta
    private let old = Books.old

    private func harness(_ list: [ReadingItem]) -> EngineHarness {
        EngineHarness {
            $0.prefs.reading.reminderStyle = .corner
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.reading.list = list
        }
    }

    private func invite(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingInvite(level: .nudge), h).inspect()
    }

    private func pill(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingTimerPill(), h).inspect()
    }

    private func doneCard(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingDoneCard(), h).inspect()
    }

    private func timedOut(_ list: [ReadingItem]) -> EngineHarness {
        let h = harness(list)
        h.engine.startReading()
        h.advance(minutes: 16)
        return h
    }

    @Test func inviteShowsUpNextWithAPick() throws {
        let h = harness([alpha, beta])
        h.showReminder(.reading)
        #expect(try invite(h).find(text: "Up next: Alpha") != nil)
    }

    @Test func inviteHasNoUpNextWithoutAPick() throws {
        let h = harness([old])
        h.showReminder(.reading)
        let sut = try invite(h)
        #expect(!MenuFind.hasText(sut, containing: "Up next"))
        #expect(try sut.find(text: "15 calm minutes with your book.") != nil)
    }

    @Test func pillCaptionIsThePickTitle() throws {
        let h = harness([alpha, beta])
        h.engine.startReading()
        let sut = try pill(h)
        #expect(try sut.find(text: "Alpha") != nil)
        #expect(Find.lacks(sut, text: "Boi is reading with you"))
    }

    @Test func finishedItEndsTheSessionAndMarksThePickDone() throws {
        let h = harness([alpha, beta])
        h.engine.startReading()
        h.advance(minutes: 5)
        try Find.button(pill(h), holding: "Finished it").tap()
        #expect(h.engine.session(.reading) == nil)
        #expect(h.history.appended == [.done(.reading, 15, at: day(2026, 3, 4, 10, 5))])
        #expect(h.engine.readingPick == beta)
        #expect(h.engine.data.prefs.reading.list.first { $0.id == alpha.id }?.doneOn != nil)
    }

    @Test func pillWithoutAPickKeepsTheCaptionAndHasNoFinishedIt() throws {
        let h = harness([old])
        h.engine.startReading()
        let sut = try pill(h)
        #expect(try sut.find(text: "Boi is reading with you") != nil)
        #expect(Find.lacks(sut, text: "Finished it"))
        #expect(try sut.find(text: "Stop") != nil)
    }

    @Test func thankYouAsksAboutThePick() throws {
        let h = timedOut([alpha, beta])
        let sut = try doneCard(h)
        #expect(try sut.find(text: "Did you finish Alpha?") != nil)
        #expect(try sut.find(text: "Yes, done") != nil)
        #expect(try sut.find(text: "Not yet") != nil)
        #expect(try sut.find(text: "Lovely, 15 minutes read") != nil)
        #expect(try sut.find(text: "A good start.") != nil)
    }

    @Test func yesDoneMarksThePickAndEndsTheCelebration() throws {
        let h = timedOut([alpha, beta])
        try Find.button(doneCard(h), holding: "Yes, done").tap()
        #expect(h.engine.readingPick == beta)
        #expect(h.engine.data.prefs.reading.list.first { $0.id == alpha.id }?.doneOn != nil)
        #expect(!h.engine.isCelebrating)
    }

    @Test func notYetKeepsThePickAndEndsTheCelebration() throws {
        let h = timedOut([alpha, beta])
        try Find.button(doneCard(h), holding: "Not yet").tap()
        #expect(h.engine.data.prefs.reading.list == [alpha, beta])
        #expect(!h.engine.isCelebrating)
    }

    @Test func thankYouWithoutAPickIsAsToday() throws {
        let h = timedOut([old])
        let sut = try doneCard(h)
        #expect(!MenuFind.hasText(sut, containing: "Did you finish"))
        #expect(Find.lacks(sut, text: "Yes, done"))
        #expect(Find.lacks(sut, text: "Not yet"))
        #expect(try sut.find(text: "Lovely, 15 minutes read") != nil)
    }

    @Test func thankYouDoesNotAskWhenThePickIsAlreadyRead() throws {
        let h = timedOut([alpha, beta])
        h.engine.markReadingDone(id: alpha.id)
        let sut = try doneCard(h)
        #expect(!MenuFind.hasText(sut, containing: "Did you finish"))
        #expect(Find.lacks(sut, text: "Yes, done"))
    }

    @Test(arguments: [true, false])
    func thankYouAfterAHandFinishDoesNotAsk(_ markDone: Bool) throws {
        let h = harness([alpha, beta])
        h.engine.startReading()
        h.engine.finishReading(markDone: markDone)
        let sut = try doneCard(h)
        #expect(!MenuFind.hasText(sut, containing: "Did you finish"))
        #expect(Find.lacks(sut, text: "Not yet"))
    }

    @Test func pillKeepsTheOpenedItemWhenAnotherMovesToTheTop() throws {
        let h = harness([alpha, beta])
        h.engine.startReading()
        h.engine.moveReading(id: beta.id, to: 0)
        let sut = try pill(h)
        #expect(try sut.find(text: "Alpha") != nil)
        #expect(Find.lacks(sut, text: "Beta"))
        try Find.button(sut, holding: "Finished it").tap()
        #expect(h.engine.data.prefs.reading.list.first { $0.id == alpha.id }?.doneOn != nil)
    }

    @Test func pillHasNoFinishedItWhenALinkIsAddedToAnEmptyListMidSession() throws {
        let h = harness([])
        h.engine.startReading()
        h.engine.addReading(url: "https://new.com/post", title: "New")
        let sut = try pill(h)
        #expect(Find.lacks(sut, text: "Finished it"))
        #expect(try sut.find(text: "Boi is reading with you") != nil)
    }

    @Test func pillFallsBackWhenTheOpenedItemIsRemoved() throws {
        let h = harness([alpha, beta])
        h.engine.startReading()
        h.engine.removeReading(id: alpha.id)
        let sut = try pill(h)
        #expect(Find.lacks(sut, text: "Finished it"))
        #expect(Find.lacks(sut, text: "Beta"))
        #expect(try sut.find(text: "Boi is reading with you") != nil)
    }
}
