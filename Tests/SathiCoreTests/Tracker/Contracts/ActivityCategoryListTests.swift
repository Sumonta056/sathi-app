import Foundation
import SathiCore
import Testing

@Suite("Activity category list")
struct ActivityCategoryListTests {
    private let list = ActivityCategory.defaults

    @Test func addPutsANewCategoryAtTheEnd() throws {
        let next = try #require(ActivityCategoryList.adding("  Deep work ", colorHex: 0x123456, to: list))
        #expect(next.last == ActivityCategory(name: "Deep work", colorHex: 0x123456))
        #expect(next.count == list.count + 1)
    }

    @Test(arguments: ["", "   ", "coding", "CODING"])
    func addRefusesEmptyOrTakenNames(name: String) {
        #expect(ActivityCategoryList.adding(name, colorHex: 0, to: list) == nil)
    }

    @Test func addRefusesWhenTheListIsFull() {
        let full = (1 ... Limits.categoryMax).map { ActivityCategory(name: "C\($0)", colorHex: 0) }
        #expect(Limits.categoryMax == 12)
        #expect(ActivityCategoryList.adding("One more", colorHex: 0, to: full) == nil)
    }

    @Test func namesAreCutAtTheMaximum() throws {
        let long = String(repeating: "x", count: 100)
        let next = try #require(ActivityCategoryList.adding(long, colorHex: 0, to: list))
        #expect(next.last?.name.count == Limits.categoryNameMax)
    }

    @Test func renameKeepsThePlaceAndTheColor() throws {
        let next = try #require(ActivityCategoryList.renaming("Review", to: "Code review", in: list))
        #expect(next[3] == ActivityCategory(name: "Code review", colorHex: list[3].colorHex))
        #expect(next.count == list.count)
    }

    @Test func renameRefusesATakenOrEmptyNameOrAMissingCategory() {
        #expect(ActivityCategoryList.renaming("Review", to: "email", in: list) == nil)
        #expect(ActivityCategoryList.renaming("Review", to: " ", in: list) == nil)
        #expect(ActivityCategoryList.renaming("Nope", to: "Other", in: list) == nil)
    }

    @Test func renameToTheSameNameWithOtherCaseIsAllowed() throws {
        let next = try #require(ActivityCategoryList.renaming("Email", to: "EMAIL", in: list))
        #expect(next.last?.name == "EMAIL")
    }

    @Test func removeDropsOnlyThatCategory() {
        let next = ActivityCategoryList.removing("Meeting", from: list)
        #expect(next.map(\.name) == ["Coding", "Cefalo Meetings", "Review", "Learning", "Email"])
    }

    @Test func recolorChangesOnlyTheColor() {
        let next = ActivityCategoryList.recoloring("Email", to: 0xABCDEF, in: list)
        #expect(next.last == ActivityCategory(name: "Email", colorHex: 0xABCDEF))
    }

    @Test func buddyCategoriesUseTheBuddyNames() {
        #expect(ActivityCategory.buddy(.meditation).name == "Meditation")
        #expect(ActivityCategory.buddy(.reading).name == "Reading")
        #expect(ActivityCategory.buddy(.gym).name == "Gym")
    }
}
