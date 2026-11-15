import Foundation
import SathiCore
import Testing

@Suite("Copywriter todos")
struct CopywriterTodosTests {
    @Test func fixedTexts() {
        #expect(Copywriter.todoDueToday == "Due today")
        #expect(Copywriter.todoAllowAccess == "Allow Reminders access")
        #expect(Copywriter.todoOpenSettings == "Open System Settings")
    }

    @Test func smartListNames() {
        #expect(Copywriter.todoSmartListName(.today) == "Today")
        #expect(Copywriter.todoSmartListName(.scheduled) == "Scheduled")
        #expect(Copywriter.todoSmartListName(.all) == "All")
        #expect(Copywriter.todoSmartListName(.completed) == "Completed")
    }

    @Test func completedToggle() {
        #expect(Copywriter.todoCompletedToggle(3) == "3 Completed · Show")
        #expect(Copywriter.todoCompletedToggle(0) == "0 Completed · Show")
    }

    @Test func markDoneQuestion() {
        #expect(Copywriter.todoMarkDoneTitle("Buy milk") == "Mark Buy milk done?")
    }

    @Test func daySummaryLine() {
        #expect(Copywriter.todoDaySummaryLine(done: 2, left: 5) == "To-dos: 2 done · 5 left for today")
        #expect(Copywriter.todoDaySummaryLine(done: 0, left: 0) == "To-dos: 0 done · 0 left for today")
    }
}
