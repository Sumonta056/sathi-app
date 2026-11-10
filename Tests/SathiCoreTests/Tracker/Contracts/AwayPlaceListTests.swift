import Foundation
import SathiCore
import Testing

@Suite("Away place list")
struct AwayPlaceListTests {
    private let eight = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

    @Test func theLimitsAreEightPlacesOfTwentyFourCharacters() {
        #expect(Limits.awayPlaceMax == 8)
        #expect(Limits.awayPlaceNameMax == 24)
    }

    @Test(arguments: [("Doctor", "Doctor"), ("  Doctor  ", "Doctor"), ("\n\tSchool run \n", "School run")])
    func aNameIsTrimmed(raw: String, clean: String) {
        #expect(AwayPlaceList.name(raw) == clean)
    }

    @Test func aNameIsCutToTwentyFourCharacters() {
        #expect(AwayPlaceList.name(String(repeating: "a", count: 40)) == String(repeating: "a", count: 24))
        #expect(AwayPlaceList.name(String(repeating: "b", count: 24)) == String(repeating: "b", count: 24))
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func anEmptyNameIsRefused(raw: String) {
        #expect(AwayPlaceList.name(raw) == nil)
    }

    @Test(arguments: [
        "Lunch", "Meeting", "Walk", "Commute", "Other", "Break", "lunch", "MEETING", "wAlK", " commute ", "other", "BREAK"
    ])
    func aBuiltInLabelIsRefusedWithoutRegardToCase(raw: String) {
        #expect(AwayPlaceList.name(raw) == nil)
    }

    @Test func aNameThatOnlyStartsWithABuiltInLabelIsKept() {
        #expect(AwayPlaceList.name("Lunch with Sam") == "Lunch with Sam")
    }

    @Test func cleanKeepsValidNamesInOrder() {
        #expect(AwayPlaceList.clean(["Doctor", "Gym", "School run"]) == ["Doctor", "Gym", "School run"])
        #expect(AwayPlaceList.clean([]) == [])
    }

    @Test func cleanTrimsAndDropsEmptyAndBuiltInNames() {
        #expect(AwayPlaceList.clean(["  Doctor ", "", "Lunch", "   ", "break", "Gym"]) == ["Doctor", "Gym"])
    }

    @Test func cleanDropsTheSecondNameThatIsEqualWithoutRegardToCase() {
        #expect(AwayPlaceList.clean(["Doctor", "doctor", "Gym", " DOCTOR ", "gym"]) == ["Doctor", "Gym"])
    }

    @Test func cleanKeepsTheFirstEight() {
        #expect(AwayPlaceList.clean(eight + ["P9", "P10"]) == eight)
    }

    @Test func cleanCountsOnlyValidNamesTowardsTheEight() {
        #expect(AwayPlaceList.clean(["Lunch", "", "p1"] + eight + ["P9"]) == ["p1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"])
    }

    @Test func cleanCutsLongNames() {
        let long = String(repeating: "c", count: 30)
        #expect(AwayPlaceList.clean([long]) == [String(repeating: "c", count: 24)])
    }

    @Test func addingPutsTheCleanNameAtTheEnd() {
        #expect(AwayPlaceList.adding("  Doctor ", to: ["Gym"]) == ["Gym", "Doctor"])
        #expect(AwayPlaceList.adding("Doctor", to: []) == ["Doctor"])
    }

    @Test(arguments: ["", "  ", "Lunch", "other", "Break"])
    func addingRefusesANameThatIsNotValid(raw: String) {
        #expect(AwayPlaceList.adding(raw, to: ["Gym"]) == nil)
    }

    @Test(arguments: ["Gym", "gym", " GYM "])
    func addingRefusesANameThatIsInTheListAlready(raw: String) {
        #expect(AwayPlaceList.adding(raw, to: ["Doctor", "Gym"]) == nil)
    }

    @Test func addingRefusesANinthName() {
        #expect(AwayPlaceList.adding("P9", to: eight) == nil)
        #expect(AwayPlaceList.adding("P8", to: Array(eight.dropLast())) == eight)
    }

    @Test func addingCutsALongName() {
        let long = String(repeating: "d", count: 30)
        #expect(AwayPlaceList.adding(long, to: []) == [String(repeating: "d", count: 24)])
    }
}
