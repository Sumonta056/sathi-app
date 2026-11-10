import SwiftUI

struct TrackerSize {
    var cardPadding: EdgeInsets
    var cardRadius: CGFloat
    var spacing: CGFloat
    var headerSpacing: CGFloat
    var tile: CGFloat
    var tileRadius: CGFloat
    var icon: CGFloat
    var eyebrow: CGFloat
    var title: CGFloat
    var fieldHeight: CGFloat
    var fieldRadius: CGFloat
    var fieldPadding: CGFloat
    var recentHeight: CGFloat
    var recentRadius: CGFloat
    var recentGap: CGFloat
    var chevron: CGFloat
    var boxPadding: EdgeInsets
    var boxRadius: CGFloat
    var boxSpacing: CGFloat
    var labelWidth: CGFloat
    var label: CGFloat
    var rowGap: CGFloat
    var chipHeight: CGFloat
    var chipPadding: CGFloat
    var dropHeight: CGFloat
    var dropRadius: CGFloat
    var dropPadding: CGFloat
    var dropGap: CGFloat
    var dot: CGFloat
    var check: CGFloat
    var checkRadius: CGFloat
    var checkMark: CGFloat
    var body: CGFloat
    var toggleGap: CGFloat
    var buttonHeight: CGFloat
    var buttonRadius: CGFloat
    var button: CGFloat
    var sideButton: CGFloat
    var buttonGap: CGFloat

    static func of(compact: Bool) -> TrackerSize { compact ? corner : center }

    static let corner = TrackerSize(
        cardPadding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        cardRadius: 16, spacing: 13, headerSpacing: 11, tile: 36, tileRadius: 11, icon: 16, eyebrow: 10, title: 16,
        fieldHeight: 42, fieldRadius: 11, fieldPadding: 4,
        recentHeight: 36, recentRadius: 10, recentGap: 9, chevron: 9,
        boxPadding: EdgeInsets(top: 12, leading: 13, bottom: 12, trailing: 13), boxRadius: 12, boxSpacing: 10,
        labelWidth: 64, label: 11, rowGap: 5, chipHeight: 26, chipPadding: 9,
        dropHeight: 28, dropRadius: 8, dropPadding: 10, dropGap: 7, dot: 7,
        check: 16, checkRadius: 4, checkMark: 9, body: 12, toggleGap: 9,
        buttonHeight: 40, buttonRadius: 11, button: 14, sideButton: 84, buttonGap: 8
    )

    static let center = TrackerSize(
        cardPadding: EdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24),
        cardRadius: 18, spacing: 16, headerSpacing: 12, tile: 40, tileRadius: 12, icon: 18, eyebrow: 11, title: 19,
        fieldHeight: 48, fieldRadius: 12, fieldPadding: 6,
        recentHeight: 38, recentRadius: 11, recentGap: 10, chevron: 10,
        boxPadding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16), boxRadius: 14, boxSpacing: 12,
        labelWidth: 84, label: 12, rowGap: 6, chipHeight: 28, chipPadding: 12,
        dropHeight: 30, dropRadius: 9, dropPadding: 11, dropGap: 8, dot: 8,
        check: 18, checkRadius: 5, checkMark: 10, body: 13, toggleGap: 10,
        buttonHeight: 46, buttonRadius: 12, button: 15, sideButton: 110, buttonGap: 10
    )

    var chipFont: CGFloat { label }
    var hint: CGFloat { UIMetrics.trackerHintFont }
}

extension UIMetrics {
    static let trackerHintFont: CGFloat = 11
    static let trackerDetailFont: CGFloat = 12
    static let trackerEyebrowEm: CGFloat = 0.08
    static let trackerLineGap: CGFloat = 2
    static let trackerTitleDotGap: CGFloat = 7
    static let trackerCornerCard: CGFloat = 380
    static let trackerCenterCard: CGFloat = 520
    static let trackerWelcomeCard: CGFloat = 440
    static let trackerDropPadding: CGFloat = 6
    static let trackerDropRowHeight: CGFloat = 32
    static let trackerDropRowRadius: CGFloat = 8
    static let trackerDropRowPadding: CGFloat = 9
    static let trackerDropRowGap: CGFloat = 2
    static let trackerDropFont: CGFloat = 13
    static let trackerDropHeaderPadding = EdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 8)
    static let trackerDropDividerPadding = EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
    static let trackerRecentMenuWidth: CGFloat = 290
    static let trackerCategoryButtonWidth: CGFloat = 220
    static let trackerCategoryMenuWidth: CGFloat = 250
    static let trackerDashedDot: [CGFloat] = [2, 2]
    static let trackerStillSpacing: CGFloat = 14
    static let trackerStillButton: CGFloat = 42
    static let trackerPillHeight: CGFloat = 30
    static let trackerPillPadding: CGFloat = 12
    static let trackerPillFont: CGFloat = 12
    static let trackerPlaceFont: CGFloat = 13
    static let trackerOutlineHeight: CGFloat = 38
    static let trackerOutlineFont: CGFloat = 13
    static let trackerStillSkipWidth: CGFloat = 76
    static let trackerWelcomeSpacing: CGFloat = 14
    static let trackerWelcomeRowHeight: CGFloat = 40
    static let trackerWelcomeRowFont: CGFloat = 14
    static let trackerPlaceBoxPadding = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
    static let trackerPlaceBoxRadius: CGFloat = 12
    static let trackerPlaceBoxSpacing: CGFloat = 9
    static let trackerBackDot: CGFloat = 9
    static let trackerNoteCardSpacing: CGFloat = 12
    static let trackerNoteButton: CGFloat = 34
    static let trackerNoteButtonRadius: CGFloat = 10
    static let trackerNoteRowGap: CGFloat = 8
    static let trackerPressedOpacity: Double = 0.85
}
