import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time picker")
struct TimePickerTests {
    struct ClockCase: Sendable {
        let minutes: Int
        let hour: Int
        let minute: Int
        let isPM: Bool
    }

    static let clockCases = [
        ClockCase(minutes: 0, hour: 12, minute: 0, isPM: false),
        ClockCase(minutes: 45, hour: 12, minute: 45, isPM: false),
        ClockCase(minutes: 9 * 60 + 30, hour: 9, minute: 30, isPM: false),
        ClockCase(minutes: 12 * 60, hour: 12, minute: 0, isPM: true),
        ClockCase(minutes: 12 * 60 + 15, hour: 12, minute: 15, isPM: true),
        ClockCase(minutes: 22 * 60 + 45, hour: 10, minute: 45, isPM: true),
        ClockCase(minutes: 23 * 60 + 45, hour: 11, minute: 45, isPM: true)
    ]

    @Test(arguments: clockCases)
    func splitsMinutesIntoClockParts(_ c: ClockCase) {
        let parts = TimeParts(minutes: c.minutes)
        #expect(parts.hour == c.hour)
        #expect(parts.minute == c.minute)
        #expect(parts.isPM == c.isPM)
        #expect(parts.minutes == c.minutes)
    }

    @Test func changingOnePartKeepsTheOthers() {
        let parts = TimeParts(minutes: 22 * 60 + 45)
        #expect(parts.with(hour: 7).minutes == 19 * 60 + 45)
        #expect(parts.with(minute: 15).minutes == 22 * 60 + 15)
        #expect(parts.with(isPM: false).minutes == 10 * 60 + 45)
        #expect(TimeParts(minutes: 12 * 60 + 30).with(isPM: false).minutes == 30)
    }

    @Test func offersEveryHourAndQuarterHour() {
        #expect(TimeParts.hours == [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(TimeParts.minuteOptions == [0, 15, 30, 45])
    }

    @Test func gridTapsSetTheTime() throws {
        let time = Box(22 * 60)
        let sut = try TimePickerGrid(minutes: time.binding, accent: Night.reading).inspect()
        try sut.find(button: "11").tap()
        #expect(time.value == 23 * 60)
        try sut.find(button: ":45").tap()
        #expect(time.value == 23 * 60 + 45)
        try sut.find(button: "AM").tap()
        #expect(time.value == 11 * 60 + 45)
    }

    @Test func menuShowsTheSetTime() throws {
        let sut = try TimeMenu(minutes: Box(22 * 60 + 45).binding, accent: Night.reading).inspect()
        #expect(throws: Never.self) { try sut.find(text: Fmt.timeOfDay(22 * 60 + 45)) }
    }
}
