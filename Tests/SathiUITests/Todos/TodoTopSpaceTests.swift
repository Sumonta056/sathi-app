@testable import SathiUI
import SwiftUI
import Testing

@Suite("Todos top space")
struct TodoTopSpaceTests {
    @Test func theItemsColumnStartsHigher() {
        let p = UIMetrics.todoItemsPadding
        #expect(p.top == 16)
        #expect(p.leading == 36)
        #expect(p.trailing == 36)
        #expect(p.bottom == 28)
    }

    @Test func theSideColumnStartsHigher() {
        let p = UIMetrics.todoSidePadding
        #expect(p.top == 16)
        #expect(p.leading == 16)
        #expect(p.trailing == 16)
        #expect(p.bottom == 20)
    }

    @Test func theTitleIsSmaller() {
        #expect(UIMetrics.todoTitleFont == 28)
    }

    @Test func theNarrowPaddingIsUnchanged() {
        #expect(UIMetrics.todoItemsPaddingNarrow == EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
    }
}
