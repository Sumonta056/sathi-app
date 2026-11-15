import AppKit
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Activity prompt todo fit")
struct ActivityPromptTodoFitTests {
    private func todo(_ id: String, _ title: String) -> Todo {
        makeTodo(id, title, due: TodoDue(date: Prompt.now, hasTime: true))
    }

    private func scrolls(_ s: TrackerPromptState, visibleHeight: CGFloat? = nil) -> Bool {
        let view = ActivityPromptView(state: s, model: nil, visibleHeight: visibleHeight)
        let host = NSHostingView(rootView: view.environment(\.colorScheme, .dark))
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        for _ in 0 ..< 3 {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return Self.hasScroll(host)
    }

    private static func hasScroll(_ v: NSView) -> Bool {
        if v is NSScrollView { return true }
        return v.subviews.contains { hasScroll($0) }
    }

    @Test func aShortScreenStillScrolls() {
        #expect(scrolls(Prompt.state(.stillOnIt) { $0.running = Reasons.running() }, visibleHeight: 500))
    }

    @Test func theDuePromptWithARunningActivityFitsWithNoScroll() {
        let s = Prompt.state(.todoDue) { s in
            s.todos = [todo("a", "Write report"), todo("b", "Call Sam"), todo("c", "Pay rent")]
            s.running = Reasons.running()
        }
        #expect(!scrolls(s))
    }

    @Test func theMarkDoneCardOnStillOnItFitsWithNoScroll() {
        let s = Prompt.state(.stillOnIt) { s in
            s.running = Reasons.running()
            s.todoDoneAsk = todo("a", "Write the quarterly report for the team")
        }
        #expect(!scrolls(s))
    }

    @Test func theDuePaneWithTheMostTodosFitsUnderTheHeader() {
        let long = "Write the quarterly planning report for the whole team and send it"
        let todos = (1 ... 9).map { todo("t\($0)", long) }
        let s = Prompt.state(.todoDue) { s in
            s.todos = todos
            s.running = Reasons.running()
        }
        let screen = ActivityPromptBuilder.screen(s)
        let model = ActivityPromptModel(s)
        let header = PromptHeader(screen: screen, state: s, model: model, onSkip: {})
            .frame(width: UIMetrics.activityPromptWidth)
        let headerHeight = NSHostingView(rootView: header).fittingSize.height
        let pane = NSHostingView(rootView: PromptTodoPane(model: model, todos: screen.todos)).fittingSize.height
        #expect(screen.todos.count == Limits.promptTodosShown)
        #expect(pane + headerHeight + UIMetrics.promptBorder <= UIMetrics.activityPromptHeight)
    }

    @Test(arguments: [PromptKind.welcomeBack, .center, .eventAsk])
    func theMarkDoneCardOnEveryOtherReasonFitsWithNoScroll(_ kind: PromptKind) {
        let s = Prompt.state(kind) { s in
            s.running = Reasons.running()
            s.event = Prompt.event()
            s.todoDoneAsk = todo("a", "Write the quarterly report for the team")
        }
        #expect(!scrolls(s))
    }

    @Test func theMarkDoneCardOnWhatNowFitsWithNoScroll() {
        let s = Prompt.state(.whatNow) { s in
            s.todoDoneAsk = todo("a", "Write report")
        }
        #expect(!scrolls(s))
    }
}
