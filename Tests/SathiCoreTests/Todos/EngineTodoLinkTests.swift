import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoLink")
struct EngineTodoLinkTests {
    @Test(arguments: ["https://console.typesafe.ai/homen", "http://example.com/a?b=1", "HTTPS://Example.com/x"])
    func webLinksOpen(_ link: String) async throws {
        let h = await EngineHarness.pageFixture()
        let u = try #require(URL(string: link))
        h.engine.openTodoLink(u)
        #expect(h.links.opened == [u])
        #expect(h.todos.calls.isEmpty)
    }

    @Test(arguments: ["mailto:a@b.com", "file:///tmp/x", "slack://open"])
    func otherSchemesOpenNothing(_ link: String) async throws {
        let h = await EngineHarness.pageFixture()
        try h.engine.openTodoLink(#require(URL(string: link)))
        #expect(h.links.opened.isEmpty)
    }
}
