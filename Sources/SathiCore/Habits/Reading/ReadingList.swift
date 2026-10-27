import Foundation

extension [ReadingItem] {
    var unread: [ReadingItem] { filter { $0.doneOn == nil } }

    var read: [ReadingItem] { filter { $0.doneOn != nil } }

    var pick: ReadingItem? { first { $0.doneOn == nil } }

    func adding(url: String, title: String, on day: DayKey) -> (list: [ReadingItem], result: ReadingAddResult) {
        switch ReadingLink.parse(url) {
        case let .failure(reason):
            return (self, reason)
        case let .success(link):
            let queue = unread
            if queue.contains(where: { $0.url == link }) { return (self, .duplicate) }
            if queue.count >= Limits.readingListMax { return (self, .full) }
            let item = ReadingItem(title: ReadingLink.cleanTitle(title), url: link, addedOn: day)
            return (queue + [item] + read, .added)
        }
    }

    func tidied() -> [ReadingItem] {
        var seen = Set<UUID>()
        let unique = filter { seen.insert($0.id).inserted }
        let done = unique.read.enumerated().sorted { l, r in
            let (ld, rd) = (l.element.doneOn?.raw ?? "", r.element.doneOn?.raw ?? "")
            return ld != rd ? ld > rd : l.offset < r.offset
        }
        return unique.unread + done.map(\.element)
    }

    func removing(id: UUID) -> [ReadingItem] {
        filter { $0.id != id }
    }

    func markingDone(id: UUID, on day: DayKey) -> [ReadingItem] {
        guard var item = first(where: { $0.id == id && $0.doneOn == nil }) else { return self }
        item.doneOn = day
        let rest = removing(id: id)
        return rest.unread + Array(([item] + rest.read).prefix(Limits.readingReadKeep))
    }

    func undoingDone(id: UUID) -> [ReadingItem] {
        guard var item = first(where: { $0.id == id && $0.doneOn != nil }),
              unread.count < Limits.readingListMax else { return self }
        item.doneOn = nil
        let rest = removing(id: id)
        return rest.unread + [item] + rest.read
    }

    func moving(id: UUID, to index: Int) -> [ReadingItem] {
        guard let item = first(where: { $0.id == id && $0.doneOn == nil }) else { return self }
        var queue = removing(id: id).unread
        queue.insert(item, at: Swift.max(0, Swift.min(index, queue.count)))
        return queue + read
    }
}
