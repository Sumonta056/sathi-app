import AppKit
@testable import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Activity prompt height")
struct ActivityPromptHeightTests {
    private let many = (1 ... 30).map {
        CalendarChoice(id: "c\($0)", title: "Calendar number \($0)", account: "iCloud", colorHex: 0x4CC3F5)
    }

    private func height(maxHeight: CGFloat?, calendars: [CalendarChoice]) -> CGFloat {
        let s = Prompt.state(.stillOnIt) { $0.calendars = calendars }
        let model = ActivityPromptModel(s)
        model.showsAllCalendars = true
        let view = ActivityPromptView(state: s, model: model, maxHeight: maxHeight)
        return NSHostingView(rootView: view.environment(\.colorScheme, .dark)).fittingSize.height
    }

    @Test func aTallPromptStopsAtTheMaxHeight() {
        #expect(height(maxHeight: nil, calendars: many) > 400)
        #expect(height(maxHeight: 400, calendars: many) <= 400)
    }

    @Test func aShortPromptKeepsItsOwnHeight() {
        let free = height(maxHeight: nil, calendars: [])
        #expect(height(maxHeight: free + 300, calendars: []) == free)
    }
}
