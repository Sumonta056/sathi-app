import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker category menu")
struct TrackerCategoryMenuTests {
    private let prefix = "tracker.category."
    private let twelve = (0 ..< 12).map { ActivityCategory(name: "C\($0)", colorHex: 0x4CC3F5) }

    private func menu(
        _ selected: String?,
        categories: [ActivityCategory] = ActivityCategory.defaults,
        allowsNone: Bool = true,
        picks: Box<[String?]> = Box([])
    ) -> TrackerCategoryMenu {
        TrackerCategoryMenu(
            categories: categories, selected: selected, idPrefix: prefix, allowsNone: allowsNone
        ) { picks.value.append($0) }
    }

    @Test func theButtonShowsTheSelectedName() throws {
        let sut = try menu("Review").inspect()
        #expect(Prompt.has(sut, "tracker.category.menu"))
        #expect(Prompt.hasText(sut, "Review"))
        #expect(!Prompt.hasText(sut, "No category"))
    }

    @Test func theButtonSaysNoCategoryWithNothingSelected() throws {
        let sut = try menu(nil).inspect()
        #expect(Prompt.has(sut, "tracker.category.menu"))
        #expect(Prompt.hasText(sut, "No category"))
    }

    @Test func theButtonUsesTheGivenPrefix() throws {
        let other = TrackerCategoryMenu(
            categories: ActivityCategory.defaults, selected: "Review", idPrefix: "tracker.note.category.", allowsNone: false
        ) { _ in }
        #expect(try Prompt.has(other.inspect(), "tracker.note.category.menu"))
        #expect(try Prompt.has(other.list.inspect(), "tracker.note.category.Review"))
    }

    @Test func everyCategoryHasARow() throws {
        let list = try menu("Review").list.inspect()
        for category in ActivityCategory.defaults {
            #expect(Prompt.has(list, prefix + category.name), "no row for \(category.name)")
            #expect(Prompt.hasText(list, category.name), "no text for \(category.name)")
        }
    }

    @Test func theCheckIsOnTheSelectedRowOnly() throws {
        let list = try menu("Review").list.inspect()
        #expect(Prompt.texts(list).filter { $0 == "✓" }.count == 1)
        let selected = try list.find(viewWithAccessibilityIdentifier: prefix + "Review").find(ViewType.Button.self, relation: .parent)
        #expect(Prompt.hasText(selected, "✓"))
        let other = try list.find(viewWithAccessibilityIdentifier: prefix + "Coding").find(ViewType.Button.self, relation: .parent)
        #expect(!Prompt.hasText(other, "✓"))
    }

    @Test func aPickCallsOnPickWithTheName() throws {
        let picks = Box<[String?]>([])
        try Prompt.tap(menu("Review", picks: picks).list.inspect(), prefix + "Learning")
        #expect(picks.value == ["Learning"])
    }

    @Test func theNoCategoryRowIsLastAndCallsOnPickWithNil() throws {
        let picks = Box<[String?]>([])
        let list = try menu("Review", picks: picks).list.inspect()
        #expect(Prompt.hasText(list, "No category"))
        #expect(Prompt.ids(list, prefix: prefix).last == "tracker.category.none")
        try Prompt.tap(list, "tracker.category.none")
        #expect(picks.value.count == 1)
        #expect(picks.value.first == .some(nil))
    }

    @Test func noNoCategoryRowWhenNoneIsNotAllowed() throws {
        let list = try menu("Review", allowsNone: false).list.inspect()
        #expect(Prompt.has(list, prefix + "Review"))
        #expect(!Prompt.has(list, "tracker.category.none"))
        #expect(!Prompt.hasText(list, "No category"))
    }

    @Test func twelveCategoriesGiveTwelveRows() throws {
        let fixed = try menu("C0", categories: twelve, allowsNone: false).list.inspect()
        #expect(Prompt.ids(fixed, prefix: prefix) == twelve.map { prefix + $0.name })
        let withNone = try menu("C0", categories: twelve).list.inspect()
        #expect(Prompt.ids(withNone, prefix: prefix).count == 13)
    }
}
