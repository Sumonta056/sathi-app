import Foundation
import SathiCore
import Testing

@Suite("Copywriter welcome back")
struct CopywriterWelcomeTests {
    @Test func theTwoStepsHaveTheirQuestions() {
        #expect(Copywriter.trackerWhereWereYou == "Where were you?")
        #expect(Copywriter.trackerWhatNow == "What now?")
    }

    @Test func theAddPlaceTexts() {
        #expect(Copywriter.trackerAddPlace == "Add")
        #expect(Copywriter.trackerNewPlace == "New place")
    }

    @Test func theButtons() {
        #expect(Copywriter.trackerContinue("Nuxt version work") == "Continue Nuxt version work")
        #expect(Copywriter.trackerIWasHere == "I was here")
    }

    @Test func awayTextWithANameNamesIt() {
        #expect(Copywriter.trackerAwayText(.other, name: "Doctor") == "Away · Doctor")
        #expect(Copywriter.trackerAwayText(.other, name: "School run") == "Away · School run")
    }

    @Test func awayTextWithoutANameNamesThePlace() {
        #expect(Copywriter.trackerAwayText(.other, name: nil) == "Away · Other")
        #expect(Copywriter.trackerAwayText(.lunch, name: nil) == "Away · Lunch")
        #expect(Copywriter.trackerAwayText(.lunch) == "Away · Lunch")
        #expect(Copywriter.trackerAwayText(nil, name: nil) == "Away")
    }

    @Test func theSettingsTexts() {
        #expect(Copywriter.trackerPlacesLabel == "Away places")
        #expect(Copywriter.trackerPlacesHint == "Your own answers for \"Where were you?\"")
        #expect(Copywriter.trackerPlacesEmpty == "Add a place in the Welcome back popup.")
    }
}
