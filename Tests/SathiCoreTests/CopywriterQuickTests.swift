import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Quick reminder copy")
struct CopywriterQuickTests {
    private let zone = FixedZone.berlin

    private func shortTime(_ date: Date) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = zone.timeZone
        return date.formatted(style)
    }

    @Test func eyebrowShowsTheDueTime() {
        let due = zone.date(2026, 3, 4, 14, 30)
        #expect(Copywriter.quickEyebrow(due: due, calendar: zone.calendar) == "QUICK REMINDER · " + shortTime(due))
    }

    @Test func setAtShowsTheCreationTime() {
        let created = zone.date(2026, 3, 4, 11, 5)
        #expect(Copywriter.quickSetAt(created, calendar: zone.calendar) == "You set this at " + shortTime(created) + ".")
    }

    @Test func noSnoozeLine() {
        #expect(Copywriter.quickNoSnooze == "No snoozes left. It stays until you tap Done.")
    }

    @Test func comesBackQuotesTheTextAndTheTime() {
        let at = zone.date(2026, 3, 4, 14, 35)
        let line = Copywriter.quickComesBack(text: "Call mom", at: at, calendar: zone.calendar)
        #expect(line == "“Call mom” comes back at " + shortTime(at))
    }

    @Test func comesBackCutsTextOverTheLimit() {
        let at = zone.date(2026, 3, 4, 14, 35)
        let line = Copywriter.quickComesBack(text: "Send the invoice to Rahim today", at: at, calendar: zone.calendar)
        #expect(line == "“Send the invoice to Rahi…” comes back at " + shortTime(at))
    }

    @Test func comesBackKeepsTextOfExactlyTheLimit() {
        let at = zone.date(2026, 3, 4, 14, 35)
        let text = String(repeating: "a", count: Limits.quickNoteTextMax)
        let line = Copywriter.quickComesBack(text: text, at: at, calendar: zone.calendar)
        #expect(line == "“" + text + "” comes back at " + shortTime(at))
    }

    @Test func whenSaysShowingNow() {
        let now = zone.date(2026, 3, 4, 14, 0)
        #expect(Copywriter.quickWhen(now, now: now, showing: true, calendar: zone.calendar) == "Showing now")
    }

    @Test func whenCountsDownOnTheSameDay() {
        let now = zone.date(2026, 3, 4, 14, 0)
        let fire = zone.date(2026, 3, 4, 14, 25)
        let line = Copywriter.quickWhen(fire, now: now, showing: false, calendar: zone.calendar)
        #expect(line == "in " + Fmt.short(fire.timeIntervalSince(now)))
    }

    @Test func whenSaysTomorrowOnALaterDay() {
        let now = zone.date(2026, 3, 4, 14, 0)
        let fire = zone.date(2026, 3, 5, 9, 0)
        #expect(Copywriter.quickWhen(fire, now: now, showing: false, calendar: zone.calendar) == "Tomorrow")
    }

    @Test func previewSaysToday() {
        let now = zone.date(2026, 3, 4, 10, 0)
        let date = zone.date(2026, 3, 4, 14, 30)
        #expect(Copywriter.quickPreview(date, now: now, calendar: zone.calendar) == "Today at " + shortTime(date))
    }

    @Test func previewSaysTomorrow() {
        let now = zone.date(2026, 3, 4, 10, 0)
        let date = zone.date(2026, 3, 5, 9, 0)
        #expect(Copywriter.quickPreview(date, now: now, calendar: zone.calendar) == "Tomorrow at " + shortTime(date))
    }
}
