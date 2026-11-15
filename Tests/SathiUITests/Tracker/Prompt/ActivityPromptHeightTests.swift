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

    private func size(visibleHeight: CGFloat?, calendars: [CalendarChoice]) -> CGSize {
        let s = Prompt.state(.stillOnIt) { $0.calendars = calendars }
        let model = ActivityPromptModel(s)
        model.showsAllCalendars = true
        let view = ActivityPromptView(state: s, model: model, visibleHeight: visibleHeight)
        return NSHostingView(rootView: view.environment(\.colorScheme, .dark)).fittingSize
    }

    @Test func aPromptOnABigScreenIsAlwaysTheFixedSize() {
        let fixed = CGSize(width: UIMetrics.activityPromptWidth, height: UIMetrics.activityPromptHeight)
        #expect(size(visibleHeight: nil, calendars: []) == fixed)
        #expect(size(visibleHeight: nil, calendars: many) == fixed)
        #expect(size(visibleHeight: 1000, calendars: many) == fixed)
    }

    @Test func aShortScreenShrinksThePromptToTheScreenLessTheMargins() {
        let height = size(visibleHeight: 600, calendars: many).height
        #expect(height <= 600 - 2 * UIMetrics.promptScreenMargin)
    }
}
