import SathiCore
@testable import SathiUI
import Testing

@Suite("Calendar mapping")
struct CalendarMappingTests {
    @Test("not determined maps to notAsked, granted to allowed, the rest to denied")
    func access() {
        #expect(CalendarMapping.access(notDetermined: true, granted: false) == .notAsked)
        #expect(CalendarMapping.access(notDetermined: false, granted: true) == .allowed)
        #expect(CalendarMapping.access(notDetermined: false, granted: false) == .denied)
    }

    @Test("sRGB components become 0xRRGGBB and clamp")
    func hex() {
        #expect(CalendarMapping.hex(red: 1, green: 0.5, blue: 0) == 0xFF8000)
        #expect(CalendarMapping.hex(red: 2, green: -1, blue: 1) == 0xFF00FF)
    }

    @Test("choices sort by account then title")
    func sorting() {
        let list = [
            CalendarChoice(id: "1", title: "B", account: "iCloud", colorHex: 0),
            CalendarChoice(id: "2", title: "A", account: "iCloud", colorHex: 0),
            CalendarChoice(id: "3", title: "Z", account: "Gmail", colorHex: 0)
        ]
        #expect(CalendarMapping.sorted(list).map(\.id) == ["3", "2", "1"])
    }
}
