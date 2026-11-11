import Foundation

package struct CategoryTableInput: Equatable, Sendable {
    package var name: String
    package var colorHex: UInt32
    package var seconds: TimeInterval
    package var previousSeconds: TimeInterval?

    package init(name: String, colorHex: UInt32, seconds: TimeInterval, previousSeconds: TimeInterval? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.seconds = seconds
        self.previousSeconds = previousSeconds
    }
}

package struct CategoryTableRow: Equatable, Identifiable, Sendable {
    package var id: String
    package var name: String
    package var colorHex: UInt32
    package var seconds: TimeInterval
    package var hoursText: String
    package var percentText: String
    package var change: RangeChange
    package var changeText: String
}

package struct CategoryTable: Equatable, Sendable {
    package var rows: [CategoryTableRow]
    package var totalSeconds: TimeInterval

    package var totalText: String { totalSeconds > 0 ? Fmt.short(totalSeconds) : Copywriter.categoryTableZeroTotal }

    package init(_ inputs: [CategoryTableInput]) {
        let kept = inputs.filter { $0.seconds > 0 || ($0.previousSeconds ?? 0) > 0 }
        let total = kept.reduce(0) { $0 + $1.seconds }
        totalSeconds = total
        rows = kept.enumerated()
            .sorted { $0.element.seconds != $1.element.seconds ? $0.element.seconds > $1.element.seconds : $0.offset < $1.offset }
            .enumerated()
            .map { Self.row($0.element.element, id: "\($0.offset)-\($0.element.element.name)", total: total) }
    }

    private static func row(_ input: CategoryTableInput, id: String, total: TimeInterval) -> CategoryTableRow {
        let change = input.previousSeconds.map { RangeChange(current: input.seconds, previous: $0, hasData: true) } ?? .none
        return CategoryTableRow(
            id: id,
            name: input.name,
            colorHex: input.colorHex,
            seconds: input.seconds,
            hoursText: Copywriter.categoryTableHours(input.seconds),
            percentText: Copywriter.categoryTablePercent(input.seconds, of: total),
            change: change,
            changeText: Copywriter.categoryTableChange(change)
        )
    }
}
