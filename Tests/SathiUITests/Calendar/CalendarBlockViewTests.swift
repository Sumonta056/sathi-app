import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar block view")
struct CalendarBlockViewTests {
    private let cal = Calendar.current
    private let start = day(2026, 11, 12, 10, 35)
    private let cats = [ActivityCategory(name: "Work", colorHex: 0x7FB8FF)]

    private func block(_ style: CalendarBlockStyle, minutes: Int = 65) -> CalendarBlock {
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        let a = Activity(text: "Design review", category: "Work", start: start, end: end)
        return CalendarBlock(
            id: "b", title: "Design review", interval: DateInterval(start: start, end: end), style: style,
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    private func placed(_ b: CalendarBlock, depth: Int = 0, hidden: Int = 0) -> CalendarPlacedBlock {
        var p = CalendarPlacedBlock(block: b, lane: 0, lanes: 1, depth: depth)
        p.hidden = Array(repeating: CalendarPlacedBlock(block: b, lane: 0, lanes: 1), count: hidden)
        return p
    }

    private func context(_ b: CalendarBlock) -> CalendarBlockContext {
        let text = CalendarBlockText(
            time: Fmt.shortRange(b.interval.start, b.interval.end, calendar: cal),
            spoken: Copywriter.calendarBlockSpoken(b.title, b.interval.start, b.interval.end, calendar: cal)
        )
        return CalendarBlockContext(texts: [b.id: text], categories: cats)
    }

    private func view(_ p: CalendarPlacedBlock, height: CGFloat) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarActivityBlock(placed: p, height: height, context: context(p.block)).inspect()
    }

    private func images(_ sut: InspectableView<ViewType.ClassifiedView>) -> [String] {
        sut.findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
    }

    private func has(_ sut: InspectableView<ViewType.ClassifiedView>, id: String) -> Bool {
        (try? sut.find(viewWithAccessibilityIdentifier: id)) != nil
    }

    @Test func textNeedsTheMinimumHeight() {
        #expect(!CalendarBlockFit.showsText(height: UIMetrics.calendarBlockMinTextHeight - 1))
        #expect(CalendarBlockFit.showsText(height: UIMetrics.calendarBlockMinTextHeight))
        #expect(!CalendarBlockFit.showsTimeRange(height: UIMetrics.calendarTimeRangeMinHeight - 1))
        #expect(CalendarBlockFit.showsTimeRange(height: UIMetrics.calendarTimeRangeMinHeight))
    }

    @Test func sizesMatchTheDesign() {
        #expect(UIMetrics.calendarBlockFont == 12)
        #expect(UIMetrics.calendarBlockTimeFont == 10.5)
        #expect(UIMetrics.calendarCascadeIndent == 14)
        #expect(UIMetrics.calendarBlockMinTextHeight == 26)
        #expect(UIMetrics.calendarEventRadius == 8)
        #expect(UIMetrics.calendarTitleLinesMax == 3)
        #expect(UIMetrics.calendarHourHeight == 60)
    }

    @Test func activityHasNoIconAndNoOutline() throws {
        let sut = try view(placed(block(.activity(category: "Work"))), height: UIMetrics.calendarTimeRangeMinHeight)
        #expect(images(sut).isEmpty)
        #expect(!has(sut, id: "calendar.block.outline"))
    }

    @Test func shortBlockShowsItsLengthOnTheRight() throws {
        let sut = try view(placed(block(.activity(category: "Work"), minutes: 8)), height: UIMetrics.calendarBlockMinTextHeight)
        #expect(throws: Never.self) { try sut.find(text: "Design review") }
        #expect(throws: Never.self) { try sut.find(text: "8 m") }
    }

    @Test func tallBlockShowsTheTimeRangeBelowTheTitle() throws {
        let b = block(.activity(category: "Work"))
        let sut = try view(placed(b), height: UIMetrics.calendarTimeRangeMinHeight)
        #expect(throws: Never.self) { try sut.find(text: Fmt.shortRange(b.interval.start, b.interval.end, calendar: cal)) }
        #expect(Find.lacks(sut, text: "1 h 05 m"))
    }

    @Test func tinyBlockHasNoTextButStillSpeaks() throws {
        let b = block(.activity(category: "Work"))
        let sut = try view(placed(b), height: UIMetrics.calendarBlockMinTextHeight - 1)
        #expect(sut.findAll(ViewType.Text.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: context(b).text(b).spoken) }
    }

    @Test func joinedUsesItsCategoryFillAndShowsTheLinkIcon() throws {
        let joined = CalendarBlockLook.of(.joined(category: "Work"), categories: cats)
        let activity = CalendarBlockLook.of(.activity(category: "Work"), categories: cats)
        #expect(joined == activity)
        #expect(joined.fill != Color(hex: 0x1E4635))
        let sut = try view(placed(block(.joined(category: "Work"))), height: UIMetrics.calendarTimeRangeMinHeight)
        #expect(images(sut) == ["link"])
    }

    @Test func activityFillIsSolidCategoryColorMixedOnThePage() {
        let look = CalendarBlockLook.of(.activity(category: "Work"), categories: cats)
        let mixed = SathiUI.RGB(hex: NightHex.card).mix(SathiUI.RGB(hex: 0x7FB8FF), UIMetrics.calendarActivityTint).color()
        #expect(look.fill == mixed)
        #expect(look.stroke == nil)
    }

    @Test func eventUsesAnOutlineInItsCalendarColor() {
        let look = CalendarBlockLook.of(.event(colorHex: 0x4285F4), categories: [])
        #expect(look.stroke == Color(hex: 0x4285F4))
        #expect(look.fill == Night.card)
        #expect(look.text == Night.text)
    }

    @Test func awayIsAGreyFillWithNoOutline() {
        let look = CalendarBlockLook.of(.away, categories: [])
        #expect(look.fill == Night.calendarAway)
        #expect(look.stroke == nil)
        #expect(look.text == Night.muted)
    }

    @Test func raisedBlockHasTheRingAndFlatBlockHasNone() throws {
        let b = block(.activity(category: "Work"))
        #expect(try has(view(placed(b, depth: 1), height: UIMetrics.calendarTimeRangeMinHeight), id: "calendar.block.ring"))
        #expect(try !has(view(placed(b), height: UIMetrics.calendarTimeRangeMinHeight), id: "calendar.block.ring"))
    }

    @Test func hiddenBlocksShowAsAPlusChip() throws {
        let sut = try view(placed(block(.activity(category: "Work")), hidden: 2), height: UIMetrics.calendarTimeRangeMinHeight)
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarHiddenCount(2)) }
    }

    @Test func pressSendsTheBlock() throws {
        let b = block(.activity(category: "Work"))
        var pressed: [String] = []
        var ctx = context(b)
        ctx.press = { block, _ in pressed.append(block.id) }
        try CalendarActivityBlock(placed: placed(b), height: UIMetrics.calendarTimeRangeMinHeight, context: ctx).inspect().button().tap()
        #expect(pressed == ["b"])
    }
}
