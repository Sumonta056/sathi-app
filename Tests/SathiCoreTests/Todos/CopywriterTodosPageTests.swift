import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("CopywriterTodosPage")
struct CopywriterTodosPageTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }
    private var now: Date { z.date(2026, 3, 4, 10) }

    @Test func pageAndSettingsTitles() {
        #expect(Copywriter.mainPageTodos == "To-dos")
        #expect(Copywriter.settingsPageTitle(.todos) == "To-dos")
        #expect(Copywriter.settingsHeaderTitle(.todos) == "To-dos")
        #expect(Copywriter.sidebarSettingsTitle(.todos) == "To-dos")
    }

    @Test func dateOnlyLabelsUseRelativeWords() {
        func label(_ d: Int) -> String {
            Copywriter.todoDueText(TodoDue(date: z.date(2026, 3, d), hasTime: false), now: now, calendar: cal)
        }
        #expect(label(4) == "Today")
        #expect(label(5) == "Tomorrow")
        #expect(label(3) == "Yesterday")
    }

    @Test func timedLabelsAddTheTime() {
        let t = Copywriter.todoDueText(TodoDue(date: z.date(2026, 3, 4, 14, 30), hasTime: true), now: now, calendar: cal)
        #expect(t == "Today · " + Fmt.timeOfDay(14 * 60 + 30, calendar: cal))
        let tomorrow = Copywriter.todoDueText(TodoDue(date: z.date(2026, 3, 5, 9), hasTime: true), now: now, calendar: cal)
        #expect(tomorrow == "Tomorrow · " + Fmt.timeOfDay(9 * 60, calendar: cal))
    }

    @Test(arguments: [(0, nil), (1, "High"), (4, "High"), (5, "Medium"), (6, "Low"), (9, "Low")] as [(Int, String?)])
    func priorityText(_ priority: Int, _ expected: String?) {
        #expect(Copywriter.todoPriorityText(priority) == expected)
    }

    @Test func repeatsLabel() {
        #expect(Copywriter.todoRepeats == "Repeats")
    }

    @Test func deleteConfirmNamesTheTodo() {
        #expect(Copywriter.todoDeleteConfirm("Buy milk") == "Delete “Buy milk”?")
    }
}
