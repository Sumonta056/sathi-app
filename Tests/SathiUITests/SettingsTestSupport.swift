import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

struct LabelNotFound: Error {
    let label: String
}

@MainActor
enum Find {
    static func button(_ sut: InspectableView<some BaseViewType>, label: String) throws -> InspectableView<ViewType.Button> {
        let view = try sut.find(viewWithAccessibilityLabel: label)
        if let b = try? view.button() { return b }
        return try view.find(ViewType.Button.self, relation: .parent)
    }

    static func button(_ sut: InspectableView<some BaseViewType>, holding text: String) throws -> InspectableView<ViewType.Button> {
        try sut.find(text: text).find(ViewType.Button.self, relation: .parent)
    }

    static func button(_ sut: InspectableView<some BaseViewType>, label: String, near text: String) throws -> InspectableView<ViewType.Button> {
        var node = try sut.find(text: text).parent()
        for _ in 0 ..< 16 {
            let hits = node.findAll(where: { (try? $0.accessibilityLabel().string()) == label })
            if hits.count == 1 { return try button(node, label: label) }
            if hits.count > 1 { break }
            node = try node.parent()
        }
        throw LabelNotFound(label: label)
    }

    static func lacks(_ sut: InspectableView<some BaseViewType>, text: String) -> Bool {
        (try? sut.find(text: text)) == nil
    }
}

@MainActor
func hosted(_ view: some View, _ h: EngineHarness) -> some View {
    view.environmentObject(h.engine)
}
