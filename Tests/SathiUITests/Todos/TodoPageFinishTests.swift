import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos page done animation")
struct TodoPageFinishTests {
    @Test func tickOnThePageWritesNothingAtOnce() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        try Find.button(sut, label: Copywriter.todoMarkDone, near: "Alpha").tap()
        await Task.yield()
        #expect(h.todos.calls.isEmpty)
    }
}
