import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter welcome back")
struct CopywriterWelcomeTests {
    private let zone = FixedZone.berlin

    @Test func theTitleAsksWhereYouWere() {
        #expect(Copywriter.trackerWelcomeBack == "Welcome back. Where were you?")
    }

    @Test func theTwoStepsHaveTheirQuestions() {
        #expect(Copywriter.trackerWhereWereYou == "Where were you?")
        #expect(Copywriter.trackerWhatNow == "What now?")
    }

    @Test func theAddPlaceTexts() {
        #expect(Copywriter.trackerAddPlace == "Add")
        #expect(Copywriter.trackerNewPlace == "New place")
        #expect(Copywriter.trackerPlaceKept == "Sathi keeps this place as a chip. Remove it in Settings → Activity tracker.")
    }

    @Test func theButtons() {
        #expect(Copywriter.trackerStartSomethingNew == "Start something new")
        #expect(Copywriter.trackerContinue("Nuxt version work") == "Continue Nuxt version work")
        #expect(Copywriter.trackerIWasHere == "I was here")
    }

    @Test func theKeyHintNamesContinueAndEsc() {
        #expect(Copywriter.trackerWelcomeKeys == "↵ continue · esc keep as Away")
    }

    @Test func theSavedLineWithoutAPlace() {
        let start = zone.date(2026, 3, 4, 12, 30)
        let end = zone.date(2026, 3, 4, 13, 15)
        let span = Copywriter.trackerSpan(start, end, calendar: zone.calendar)
        #expect(Copywriter.trackerAwaySaved(start, end, place: nil, calendar: zone.calendar) == "Sathi saves " + span + " as Away")
    }

    @Test(arguments: ["Lunch", "Doctor", "School run"])
    func theSavedLineNamesThePlace(_ place: String) {
        let start = zone.date(2026, 3, 4, 12, 30)
        let end = zone.date(2026, 3, 4, 13, 15)
        let span = Copywriter.trackerSpan(start, end, calendar: zone.calendar)
        #expect(Copywriter.trackerAwaySaved(start, end, place: place, calendar: zone.calendar) == "Sathi saves " + span + " as Away · " + place)
    }

    @Test func theSavedLineUsesTheClockOfTheCalendarZone() {
        let start = zone.date(2026, 3, 4, 12, 30)
        let end = zone.date(2026, 3, 4, 13, 15)
        let berlin = Copywriter.trackerAwaySaved(start, end, place: nil, calendar: zone.calendar)
        let newYork = Copywriter.trackerAwaySaved(start, end, place: nil, calendar: FixedZone.newYork.calendar)
        #expect(berlin != newYork)
        #expect(newYork == "Sathi saves " + Copywriter.trackerSpan(start, end, calendar: FixedZone.newYork.calendar) + " as Away")
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
