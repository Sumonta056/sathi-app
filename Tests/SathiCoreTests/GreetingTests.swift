import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Greeting")
struct GreetingTests {
    private let zone = FixedZone.berlin

    private func greeting(_ hour: Int, _ minute: Int, name: String = "Mridul") -> String {
        Copywriter.greeting(at: zone.date(2026, 3, 4, hour, minute), name: name, calendar: zone.calendar)
    }

    @Test(arguments: [(5, 0), (11, 59)])
    func morningRunsFromFiveToNoon(_ hour: Int, _ minute: Int) {
        #expect(greeting(hour, minute) == "Good morning, Mridul")
    }

    @Test(arguments: [(12, 0), (16, 59)])
    func afternoonRunsFromNoonToFive(_ hour: Int, _ minute: Int) {
        #expect(greeting(hour, minute) == "Good afternoon, Mridul")
    }

    @Test(arguments: [(17, 0), (23, 59), (0, 0), (4, 59)])
    func eveningCoversTheRest(_ hour: Int, _ minute: Int) {
        #expect(greeting(hour, minute) == "Good evening, Mridul")
    }

    @Test func blankNameBecomesFriend() {
        #expect(greeting(9, 0, name: "  ") == "Good morning, friend")
    }

    @Test func hourIsReadInTheGivenCalendar() {
        let tokyo = FixedZone("Asia/Tokyo")
        let morningInTokyo = tokyo.date(2026, 3, 4, 8)
        #expect(Copywriter.greeting(at: morningInTokyo, name: "Mridul", calendar: tokyo.calendar) == "Good morning, Mridul")
        #expect(Copywriter.greeting(at: morningInTokyo, name: "Mridul", calendar: zone.calendar) == "Good evening, Mridul")
    }

    @Test func hourBoundariesLiveInLimits() {
        #expect(Limits.morningStartHour == 5)
        #expect(Limits.afternoonStartHour == 12)
        #expect(Limits.eveningStartHour == 17)
    }
}
