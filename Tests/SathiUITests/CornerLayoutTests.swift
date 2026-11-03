import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Corner layout")
struct CornerLayoutTests {
    private let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let inset = CGPoint(x: -12, y: -12)
    private let overlap: CGFloat = 36
    private let gap: CGFloat = 12

    private func layout(_ sizes: [CGSize], in frame: CGRect? = nil) -> [CGPoint] {
        CornerLayout.origins(sizes: sizes, in: frame ?? self.frame, inset: inset, overlap: overlap, gap: gap)
    }

    private func panel(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        CGSize(width: width, height: height)
    }

    @Test func emptySizesGiveNoOrigins() {
        #expect(layout([]).isEmpty)
    }

    @Test func panelsThatFitStackDownOneColumnWithOverlap() {
        let origins = layout([panel(330, 200), panel(300, 150), panel(330, 100)])
        #expect(origins == [
            CGPoint(x: 1098, y: 688),
            CGPoint(x: 1128, y: 574),
            CGPoint(x: 1098, y: 510)
        ])
    }

    @Test func aPanelThatDoesNotFitStartsANewColumnToTheLeft() throws {
        let origins = layout([panel(330, 400), panel(330, 400), panel(330, 400)])
        try #require(origins.count == 3)
        #expect(origins[0] == CGPoint(x: 1098, y: 488))
        #expect(origins[1] == CGPoint(x: 1098, y: 124))
        #expect(origins[2].y + 400 == frame.maxY + inset.y)
        #expect(origins[2].x + 330 == origins[0].x - gap)
        #expect(origins[2] == CGPoint(x: 756, y: 488))
    }

    @Test func manyTallPanelsNeverGoBelowTheScreen() {
        let sizes = Array(repeating: panel(330, 400), count: 5)
        let origins = layout(sizes)
        #expect(origins.count == 5)
        for origin in origins {
            #expect(origin.y >= frame.minY)
        }
        #expect(origins.map(\.y) == [488, 124, 488, 124, 488])
        #expect(origins.map(\.x) == [1098, 1098, 756, 756, 414])
    }

    @Test func theNextColumnStartsLeftOfTheWidestPanel() throws {
        let origins = layout([panel(300, 400), panel(330, 400), panel(300, 400)])
        try #require(origins.count == 3)
        #expect(origins[0] == CGPoint(x: 1128, y: 488))
        #expect(origins[1] == CGPoint(x: 1098, y: 124))
        #expect(origins[2] == CGPoint(x: 786, y: 488))
    }

    @Test func aPanelTallerThanTheScreenStaysInTheFirstColumn() {
        let origins = layout([panel(330, 1000)])
        #expect(origins == [CGPoint(x: 1098, y: -112)])
    }

    @Test func aPanelAfterATooTallPanelMovesToTheNextColumn() {
        let origins = layout([panel(330, 1000), panel(330, 100)])
        #expect(origins == [CGPoint(x: 1098, y: -112), CGPoint(x: 756, y: 788)])
    }

    @Test func theScreenBottomIsTheFramesMinY() {
        let screen = CGRect(x: 1440, y: -200, width: 1280, height: 800)
        let origins = layout([panel(330, 400), panel(330, 400)], in: screen)
        #expect(origins == [CGPoint(x: 2378, y: 188), CGPoint(x: 2378, y: -176)])
    }

    @Test func columnsSitAsCloseAsPanelsInAColumn() {
        let shadow = 2 * UIMetrics.bubbleShadowPadding
        let betweenColumns = UIMetrics.cornerColumnGap + shadow
        let betweenRows = shadow - UIMetrics.cornerStackOverlap
        #expect(betweenColumns == betweenRows)
    }
}
