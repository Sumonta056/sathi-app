@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("To-dos narrow layout")
struct TodosNarrowTests {
    @Test func narrowLayoutUsesTheSlimListColumn() {
        #expect(TodoSideColumn.width(NarrowSupport.narrow) == UIMetrics.todoSideWidthNarrow)
        #expect(UIMetrics.todoSideWidthNarrow < UIMetrics.todoSideWidth)
    }

    @Test func wideLayoutKeepsTheFullListColumn() {
        #expect(TodoSideColumn.width(NarrowSupport.wide) == UIMetrics.todoSideWidth)
        #expect(TodoSideColumn.width(NarrowSupport.drawerOnly) == UIMetrics.todoSideWidth)
    }

    @Test func narrowLayoutUsesTheSmallItemsPadding() {
        #expect(TodoItemsColumn.padding(NarrowSupport.narrow) == UIMetrics.todoItemsPaddingNarrow)
        #expect(TodoItemsColumn.padding(NarrowSupport.wide) == UIMetrics.todoItemsPadding)
    }

    @Test func theItemsColumnKeepsRoomAtTheSmallestWindow() {
        let page = UIMetrics.mainWindowMinSize.width - UIMetrics.sidebarRailWidth
        let padding = UIMetrics.todoItemsPaddingNarrow
        let items = page - UIMetrics.todoSideWidthNarrow - padding.leading - padding.trailing
        #expect(items >= UIMetrics.todoItemsMinWidth)
    }
}
