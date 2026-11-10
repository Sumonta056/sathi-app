import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Center prompt header")
struct CenterPromptHeaderTests {
    @Test func showsTheSameHeaderAsWhatNowWithALogEyebrow() throws {
        let sut = try CenterPromptView(state: Prompt.state(.center)).inspect()
        _ = try sut.find(text: Copywriter.trackerWhatAreYouDoingNow)
        _ = try sut.find(text: Copywriter.trackerLogEyebrow(Prompt.now, calendar: Prompt.calendar))
    }

    @Test func theLogEyebrowNamesTheTime() {
        let eyebrow = Copywriter.trackerLogEyebrow(Prompt.now, calendar: Prompt.calendar)
        #expect(eyebrow.hasPrefix("LOG ACTIVITY · "))
        #expect(eyebrow.hasSuffix(Copywriter.trackerWhatNowEyebrow(Prompt.now, calendar: Prompt.calendar).dropFirst("WHAT NOW? · ".count)))
    }
}
