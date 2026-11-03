import SathiCore
import Testing

@Suite("Time block settings copy")
struct CopywriterBlockSettingsTests {
    @Test func fixedLines() {
        #expect(Copywriter.blockSettingsTitle == "Time blocks")
        #expect(Copywriter.blockSettingsSubtitle == "Sathi writes 1 event when a time block ends. It never reads your events.")
        #expect(Copywriter.blockSettingsAllowed == "Allowed")
        #expect(Copywriter.blockSettingsNotAllowed == "Not allowed")
        #expect(Copywriter.blockSettingsNotAsked == "Not asked yet")
        #expect(Copywriter.blockSettingsAllowAccess == "Allow access")
        #expect(Copywriter.blockSettingsNeedsAccess == "Allow calendar access to pick a calendar.")
        #expect(Copywriter.blockSettingsDefaultCalendar == "Default calendar")
        #expect(Copywriter.blockSettingsCalendarNote == "Birthdays, Holidays, and subscribed calendars are not shown.")
        #expect(Copywriter.blockSettingsDisplay == "While a time block runs, show")
        #expect(Copywriter.blockSettingsMenuBar == "Menu bar only")
        #expect(Copywriter.blockSettingsWidget == "Corner widget")
        #expect(Copywriter.blockSettingsSound == "Sound when a time block ends")
        #expect(Copywriter.blockSettingsAccess == "Calendar access")
        #expect(Copywriter.blockSettingsDefaultHint == "Start uses this one. You can pick another one each time.")
        #expect(Copywriter.blockSettingsSoundHint == "A soft sound plays with the corner popup.")
    }

    @Test func openSystemSettingsReusesTheMenuCardLabel() {
        #expect(Copywriter.blockOpenSettings == "Open System Settings")
    }
}
