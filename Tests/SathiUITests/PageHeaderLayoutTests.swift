import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Page header layout")
struct PageHeaderLayoutTests {
    @Test func staysOnOneRowWhenTitleAndControlsFit() {
        #expect(PageHeaderLayout.fitsOneRow(width: 800, title: 200, controls: 580, gap: 16))
    }

    @Test func wrapsWhenTitleAndControlsDoNotFit() {
        #expect(!PageHeaderLayout.fitsOneRow(width: 700, title: 200, controls: 580, gap: 16))
    }

    @Test func wrapsWhenTheGapTipsItOver() {
        #expect(!PageHeaderLayout.fitsOneRow(width: 790, title: 200, controls: 580, gap: 16))
    }
}
