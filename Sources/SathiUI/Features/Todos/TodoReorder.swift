import SwiftUI

struct TodoReorder: Equatable {
    var id: String?
    var peers: [String] = []
    var mids: [CGFloat] = []
    var height: CGFloat = 0
    var from = 0
    var to = 0
    var dy: CGFloat = 0

    mutating func start(id: String, peers: [String], frames: [String: CGRect]) {
        let rects = peers.compactMap { frames[$0] }
        guard rects.count == peers.count, let from = peers.firstIndex(of: id) else { return }
        self = TodoReorder(id: id, peers: peers, mids: rects.map(\.midY), height: rects[from].height, from: from, to: from)
    }

    mutating func update(dy: CGFloat) {
        self.dy = dy
        to = Self.target(from: from, mids: mids, dy: dy)
    }

    func offset(_ rowID: String) -> CGFloat {
        guard id != nil, let i = peers.firstIndex(of: rowID) else { return 0 }
        if i == from { return dy }
        return CGFloat(Self.shift(i, from: from, to: to)) * height
    }

    var before: String? { Self.before(peers, from: from, to: to) }

    static func target(from: Int, mids: [CGFloat], dy: CGFloat) -> Int {
        let mid = mids[from] + dy
        return mids.enumerated().filter { $0.offset != from && $0.element < mid }.count
    }

    static func shift(_ i: Int, from: Int, to: Int) -> Int {
        if i > from, i <= to { return -1 }
        if i < from, i >= to { return 1 }
        return 0
    }

    static func before(_ ids: [String], from: Int, to: Int) -> String? {
        var others = ids
        others.remove(at: from)
        return to < others.count ? others[to] : nil
    }
}

struct TodoRowFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

final class TodoRowFrames {
    var all: [String: CGRect] = [:]
}
