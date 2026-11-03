import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Length chips")
struct LengthChipsTests {
    private static let labels = ["Open", "15", "30", "40", "45", "1 h", "2 h"]

    private func chips(_ picked: Picked<TimeBlockLength>) throws -> InspectableView<ViewType.ClassifiedView> {
        try LengthChips(selection: picked.binding).inspect()
    }

    @Test func labelsFollowTheLengthChoices() throws {
        let sut = try chips(Picked(.minutes(30)))
        #expect(TimeBlockLength.choices.count == Self.labels.count)
        for label in Self.labels {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.chip." + label) }
        }
    }

    @Test(arguments: zip(Self.labels, TimeBlockLength.choices))
    func tappingAChipSelectsItsLength(_ label: String, _ length: TimeBlockLength) throws {
        let picked = Picked<TimeBlockLength>(.minutes(15) == length ? .open : .minutes(15))
        let sut = try chips(picked)
        try sut.find(viewWithAccessibilityIdentifier: "block.chip." + label).find(ViewType.Button.self, relation: .parent).tap()
        #expect(picked.value == length)
    }
}
