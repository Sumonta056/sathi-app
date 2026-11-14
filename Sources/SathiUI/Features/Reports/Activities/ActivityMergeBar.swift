import SathiCore
import SwiftUI

struct ActivityMergeBar: View {
    let check: ManualMergeCheck?
    let calendar: Calendar
    let canUndo: Bool
    let actions: ActivityDayActions
    @Binding var selected: Set<ActivityID>
    @Binding var error: String?

    static func state(_ check: ManualMergeCheck, calendar: Calendar) -> (enabled: Bool, line: String) {
        switch check {
        case let .ok(plan):
            return (true, Copywriter.mergePreview(
                count: plan.rows.count, start: plan.merged.start, end: plan.merged.end, calendar: calendar
            ))
        case let .blocked(reason):
            return (false, Copywriter.mergeBlocked(reason))
        }
    }

    static func line(_ result: ManualMergeResult) -> String? {
        switch result {
        case .merged: nil
        case let .blocked(reason): Copywriter.mergeBlocked(reason)
        case .calendarFailed: Copywriter.mergeCalendarFailed
        case .calendarPartlyChanged: Copywriter.mergeCalendarPartly
        }
    }

    static func line(_ result: ManualMergeUndoResult) -> String? {
        result == .restoredCalendarFailed ? Copywriter.mergeUndoCalendarFailed : nil
    }

    static func shows(selected: Set<ActivityID>, canUndo: Bool, error: String?) -> Bool {
        !selected.isEmpty || canUndo || error != nil
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.mergeBarRadius, style: .continuous)
        let state = check.map { Self.state($0, calendar: calendar) }
        HStack(spacing: UIMetrics.mergeBarGap) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                if let state { Text(verbatim: state.line).foregroundStyle(Night.text) }
                if let error { Text(verbatim: error).foregroundStyle(Night.tracker) }
            }
            .font(Typography.hint)
            .frame(maxWidth: .infinity, alignment: .leading)
            if canUndo { button(Copywriter.mergeUndo, enabled: true, action: undo) }
            if state != nil { button(Copywriter.mergeButton, enabled: state?.enabled == true, action: merge) }
        }
        .padding(UIMetrics.mergeBarPadding)
        .background(shape.fill(Night.trackerInset))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func button(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.mergeBarButton))
            .disabled(!enabled)
            .opacity(enabled ? 1 : UIMetrics.mergeDisabledOpacity)
    }

    private func merge() {
        let result = actions.merge(selected)
        error = Self.line(result)
        if case .merged = result { selected = [] }
    }

    private func undo() {
        error = Self.line(actions.undoMerge())
    }
}
