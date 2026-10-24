import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

@MainActor
enum MenuFind {
    static func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    static func hasText(_ sut: InspectableView<some BaseViewType>, containing part: String) -> Bool {
        texts(sut).contains { $0.contains(part) }
    }

    static func accessibilityValue(_ sut: InspectableView<some BaseViewType>, label: String) throws -> String {
        try sut.find(viewWithAccessibilityLabel: label).accessibilityValue().string()
    }

    static func accessibilityValues(_ sut: InspectableView<some BaseViewType>) -> [String] {
        let own = (try? sut.accessibilityValue().string()).map { [$0] } ?? []
        let nested = sut.findAll(where: { (try? $0.accessibilityValue().string()) != nil })
            .compactMap { try? $0.accessibilityValue().string() }
        return own + nested
    }

    static func control(_ sut: InspectableView<some BaseViewType>, _ name: String) throws -> InspectableView<ViewType.Button> {
        if let b = try? Find.button(sut, label: name) { return b }
        return try Find.button(sut, holding: name)
    }
}
