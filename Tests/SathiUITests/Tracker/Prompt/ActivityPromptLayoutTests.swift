import Foundation
@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt layout")
struct ActivityPromptLayoutTests {
    private func view(_ visibleHeight: CGFloat?, kind: PromptKind = .whatNow) throws -> InspectableView<ViewType.ClassifiedView> {
        let s = Reasons.withKeep(kind, calls: PromptCalls())
        return try ActivityPromptView(state: s, model: nil, visibleHeight: visibleHeight).inspect()
    }

    private func rows(_ sut: InspectableView<ViewType.ClassifiedView>, has: [String], not: [String]) -> Int {
        sut.findAll(ViewType.HStack.self).filter {
            let texts = Prompt.texts($0)
            return has.allSatisfy(texts.contains) && not.allSatisfy { !texts.contains($0) }
        }.count
    }

    @Test func noScrollViewWhenTheScreenFits() throws {
        #expect(try view(nil).findAll(ViewType.ScrollView.self).isEmpty)
        #expect(try view(752).findAll(ViewType.ScrollView.self).isEmpty)
        #expect(try view(1200, kind: .stillOnIt).findAll(ViewType.ScrollView.self).isEmpty)
    }

    @Test func aScrollViewOnAShortScreen() throws {
        #expect(try view(751).findAll(ViewType.ScrollView.self).count == 1)
        #expect(try view(600).findAll(ViewType.ScrollView.self).count == 1)
    }

    @Test func theFooterStaysOutsideTheScrollOnAShortScreen() throws {
        let sut = try view(600)
        let scroll = try sut.find(ViewType.ScrollView.self)
        #expect(!Prompt.has(scroll, "tracker.start"))
        #expect(Prompt.has(sut, "tracker.start"))
    }

    @Test func forAndAskMeShareOneRow() throws {
        let shared = try rows(
            view(nil),
            has: [Copywriter.trackerFor, Copywriter.trackerAskMe],
            not: [Copywriter.trackerCalendar, Copywriter.trackerCategory, Copywriter.trackerAway, Copywriter.activityPromptQuiet]
        )
        #expect(shared >= 1)
    }

    @Test func awayAndQuietShareOneRow() throws {
        let shared = try rows(
            view(nil),
            has: [Copywriter.trackerAway, Copywriter.activityPromptQuiet],
            not: [Copywriter.trackerFor, Copywriter.trackerCalendar, Copywriter.trackerCategory, Copywriter.trackerAskMe]
        )
        #expect(shared >= 1)
    }

    @Test func theKeepButtonSitsNextToTheNameInTheRunningCard() throws {
        let card = try view(nil, kind: .stillOnIt).find(PromptRunningCard.self)
        let beside = card.findAll(ViewType.HStack.self).filter {
            Prompt.texts($0).contains("Code review") && Prompt.has($0, "prompt.keep")
        }
        #expect(!beside.isEmpty)
    }
}
