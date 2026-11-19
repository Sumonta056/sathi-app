import Foundation
import SathiCore
import Testing

@Suite("Dashboard sidebar copy")
struct CopywriterDashboardSidebarTests {
    @Test func pageNameIsDashboard() {
        #expect(Copywriter.mainPageDashboard == "Dashboard")
    }

    @Test func planHeadingIsPlan() {
        #expect(Copywriter.sidebarPlanHeading == "PLAN")
    }

    @Test(arguments: [(3, "3 due today"), (1, "1 due today"), (12, "12 due today")])
    func badgeLabelSaysHowManyAreDueToday(_ n: Int, _ expected: String) {
        #expect(Copywriter.todosBadge(n) == expected)
    }

    @Test func badgedItemLabelJoinsTitleAndBadge() {
        #expect(Copywriter.sidebarBadged("To-dos", "3 due today") == "To-dos, 3 due today")
    }
}
