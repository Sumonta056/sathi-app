import SathiCore
import Testing

@Suite("Gym popup minutes")
struct GymPopupMinutesTests {
    @Test func popupMinutesSpreadTheSessionsEvenlyOverWorkHours() {
        var g = GymPrefs()
        #expect(g.popupMinutes == [600, 720, 840, 960])
        g.sessionsPerDay = 1
        #expect(g.popupMinutes == [780])
        g.sessionsPerDay = 3
        g.startMinutes = 8 * 60
        g.endMinutes = 14 * 60
        #expect(g.popupMinutes == [540, 660, 780])
    }

    @Test func popupMinutesAreEmptyWhenWorkHoursEndAtOrBeforeTheStart() {
        var g = GymPrefs()
        g.endMinutes = g.startMinutes
        #expect(g.popupMinutes.isEmpty)
    }
}
