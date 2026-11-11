import Foundation
import SathiCore
import Testing

@Suite("Copywriter tracker popups")
struct CopywriterTrackerPopupTests {
    @Test func shortLabels() {
        #expect(Copywriter.trackerNoCategory == "No category")
    }

    @Test func theNoteFooterNamesTheMinutesUntilItCloses() {
        #expect(Copywriter.trackerNoteCloses == "Logged now · this note closes in 1 min")
    }
}
