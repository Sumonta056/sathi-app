import Foundation

package enum SpanCut {
    package static func cut(_ span: DateInterval, removing parts: [DateInterval]) -> [DateInterval] {
        var pieces = [span]
        for part in parts {
            pieces = pieces.flatMap { piece -> [DateInterval] in
                guard part.start < piece.end, part.end > piece.start else { return [piece] }
                var left: [DateInterval] = []
                if part.start > piece.start { left.append(DateInterval(start: piece.start, end: part.start)) }
                if part.end < piece.end { left.append(DateInterval(start: part.end, end: piece.end)) }
                return left
            }
        }
        return pieces
    }
}
