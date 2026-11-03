@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
func lazyField(_ sut: InspectableView<some BaseViewType>, _ placeholder: String) throws -> LazyTextField {
    try sut.find(LazyTextField.self, where: { try $0.actualView().placeholder == placeholder }).actualView()
}

@MainActor
final class FieldText {
    var value: String
    var submits = 0

    init(_ value: String = "") {
        self.value = value
    }

    func field(startsEditing: Bool = false) -> LazyTextField {
        LazyTextField(
            placeholder: "Your name",
            text: Binding(get: { self.value }, set: { self.value = $0 }),
            startsEditing: startsEditing,
            onSubmit: { self.submits += 1 }
        )
    }
}

@MainActor
@Suite("Lazy text field")
struct LazyTextFieldTests {
    @Test func atRestThereIsNoTextField() throws {
        let sut = try FieldText("Asha").field().inspect()
        #expect(sut.findAll(ViewType.TextField.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(button: "Asha") }
    }

    @Test func atRestAnEmptyValueShowsThePlaceholder() throws {
        let sut = try FieldText().field().inspect()
        #expect(sut.findAll(ViewType.TextField.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(button: "Your name") }
    }

    @Test func atRestTheButtonIsTappable() throws {
        let sut = try FieldText("Asha").field().inspect()
        #expect(throws: Never.self) { try sut.find(button: "Asha").tap() }
    }

    @Test func whileEditingATextFieldIsBoundToTheSameText() throws {
        let text = FieldText("Asha")
        let field = try text.field(startsEditing: true).inspect().find(ViewType.TextField.self)
        #expect(try field.input() == "Asha")
        try field.setInput("Bela")
        #expect(text.value == "Bela")
    }

    @Test func submitCallsTheSubmitCallback() throws {
        let text = FieldText("Asha")
        try text.field(startsEditing: true).inspect().find(ViewType.TextField.self).callOnSubmit()
        #expect(text.submits == 1)
    }
}
