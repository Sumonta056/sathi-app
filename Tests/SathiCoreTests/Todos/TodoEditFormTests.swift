import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoEditForm")
struct TodoEditFormTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }

    @Test func aTodoWithATimeFillsDateAndMinutes() {
        let todo = makeTodo("a", "Call", due: TodoDue(date: z.date(2026, 3, 5, 14, 30), hasTime: true))
        let form = TodoEditForm(todo: todo, calendar: cal)
        #expect(form.title == "Call")
        #expect(form.listID == "inbox")
        #expect(form.hasDate)
        #expect(form.minutes == 14 * 60 + 30)
        #expect(cal.startOfDay(for: form.date) == z.date(2026, 3, 5))
    }

    @Test func aDateOnlyTodoHasNoMinutes() {
        let todo = makeTodo("a", due: TodoDue(date: z.date(2026, 3, 5), hasTime: false))
        let form = TodoEditForm(todo: todo, calendar: cal)
        #expect(form.hasDate)
        #expect(form.minutes == nil)
    }

    @Test func aTodoWithoutADueHasNoDate() {
        let form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        #expect(!form.hasDate)
        #expect(form.minutes == nil)
    }

    @Test func editOfATimedDueCombinesDateAndMinutes() {
        var form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        form.hasDate = true
        form.date = z.date(2026, 3, 6, 3)
        form.minutes = 9 * 60 + 5
        #expect(form.edit(calendar: cal).due == TodoDue(date: z.date(2026, 3, 6, 9, 5), hasTime: true))
    }

    @Test func editOfADateOnlyDueIsTheStartOfThatDay() {
        var form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        form.hasDate = true
        form.date = z.date(2026, 3, 6, 17)
        form.minutes = nil
        #expect(form.edit(calendar: cal).due == TodoDue(date: z.date(2026, 3, 6), hasTime: false))
    }

    @Test func noDateMeansNoDueEvenWithMinutes() {
        var form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        form.hasDate = false
        form.minutes = 600
        #expect(form.edit(calendar: cal).due == nil)
    }

    @Test func editTrimsTheTitleAndKeepsTheNotes() {
        var form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        form.title = "  New title "
        form.notes = "line 1\nline 2"
        let edit = form.edit(calendar: cal)
        #expect(edit.title == "New title")
        #expect(edit.notes == "line 1\nline 2")
    }

    @Test(arguments: [("", false), ("   ", false), ("x", true)])
    func isValidNeedsATitle(_ title: String, _ valid: Bool) {
        var form = TodoEditForm(todo: makeTodo("a"), calendar: cal)
        form.title = title
        #expect(form.isValid == valid)
    }

    @Test func roundTripOfAnUntouchedFormKeepsTheDue() {
        let due = TodoDue(date: z.date(2026, 3, 5, 14, 30), hasTime: true)
        let form = TodoEditForm(todo: makeTodo("a", "Call", due: due), calendar: cal)
        #expect(form.edit(calendar: cal) == TodoEdit(title: "Call", notes: "", due: due))
    }
}
