import CoreGraphics

struct TodoBoardDropCard: Equatable {
    let id: String
    let frame: CGRect
}

struct TodoBoardDropColumn: Equatable {
    let frame: CGRect
    let cards: [TodoBoardDropCard]
}

struct TodoBoardSlot: Equatable {
    let id: String
    let column: Int
    let before: String?
}

enum TodoBoardDropTarget {
    static func canDrag(count: Int?, fit: Int) -> Bool {
        guard let count else { return false }
        return fit >= count
    }

    static func target(point: CGPoint, columns: [TodoBoardDropColumn], excluding: String?) -> (column: Int, before: String?) {
        guard !columns.isEmpty else { return (0, nil) }
        let column = columnIndex(point.x, columns)
        let before = columns[column].cards.first { $0.id != excluding && $0.frame.midY > point.y }?.id
        return (column, before)
    }

    static func columns(frames: [Int: CGRect], cards: [String: CGRect]) -> [TodoBoardDropColumn] {
        frames.keys.sorted().compactMap { frames[$0] }.map { frame in
            let inside = cards
                .filter { $0.value.midX >= frame.minX && $0.value.midX <= frame.maxX }
                .map { TodoBoardDropCard(id: $0.key, frame: $0.value) }
                .sorted { $0.frame.minY < $1.frame.minY }
            return TodoBoardDropColumn(frame: frame, cards: inside)
        }
    }

    private static func columnIndex(_ x: CGFloat, _ columns: [TodoBoardDropColumn]) -> Int {
        if let inside = columns.firstIndex(where: { x >= $0.frame.minX && x <= $0.frame.maxX }) { return inside }
        return columns.indices.min { distance(x, columns[$0].frame) < distance(x, columns[$1].frame) } ?? 0
    }

    private static func distance(_ x: CGFloat, _ frame: CGRect) -> CGFloat {
        x < frame.minX ? frame.minX - x : x - frame.maxX
    }
}
