import Foundation
import SathiCore
import Testing

@Suite("Time block length and text")
struct TimeBlockLengthTests {
    @Test func choicesAreOpenThenTheFixedLengths() {
        let expected: [TimeBlockLength] = [.open, .minutes(15), .minutes(30), .minutes(40), .minutes(45), .minutes(60), .minutes(120)]
        #expect(TimeBlockLength.choices == expected)
    }

    @Test func minutesIsNilForOpen() {
        #expect(TimeBlockLength.open.minutes == nil)
        #expect(TimeBlockLength.minutes(45).minutes == 45)
    }

    @Test func cleanTrims() {
        #expect(TimeBlockText.clean("  Plan  ") == "Plan")
        #expect(TimeBlockText.clean("Plan\n") == "Plan")
    }

    @Test func cleanChangesLineBreaksToSpaces() {
        #expect(TimeBlockText.clean("Write\nreport") == "Write report")
    }

    @Test func cleanCutsToSixtyCharacters() {
        let cleaned = TimeBlockText.clean(String(repeating: "x", count: 80))
        #expect(cleaned.count == 60)
        #expect(Limits.blockTitleMax == 60)
    }

    @Test func emptyTextBecomesWork() {
        #expect(TimeBlockText.clean("") == "Work")
        #expect(TimeBlockText.clean("   \n ") == "Work")
    }
}
