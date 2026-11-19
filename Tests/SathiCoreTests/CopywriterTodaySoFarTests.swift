import Foundation
import SathiCore
import Testing

@Suite("Copywriter today so far")
struct CopywriterTodaySoFarTests {
    @Test func changeUsesDayWords() {
        #expect(Copywriter.todaySoFarChange(.up(40 * 60)) == "+40m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.up(3600)) == "+1h 0m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.down(90 * 60)) == "\u{2212}1h 30m vs yesterday")
        #expect(Copywriter.todaySoFarChange(.same) == "same as yesterday")
    }

    @Test func noChangeIsEmpty() {
        #expect(Copywriter.todaySoFarChange(.none) == "")
    }
}
