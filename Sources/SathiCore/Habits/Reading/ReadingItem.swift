import Foundation

package struct ReadingItem: Codable, Equatable, Identifiable, Sendable {
    package let id: UUID
    package var title: String
    package var url: URL
    package let addedOn: DayKey
    package var doneOn: DayKey?

    package init(id: UUID = UUID(), title: String, url: URL, addedOn: DayKey, doneOn: DayKey? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.addedOn = addedOn
        self.doneOn = doneOn
    }

    enum CodingKeys: String, CodingKey {
        case id, title, url, addedOn, doneOn
    }

    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let link = try c.decode(URL.self, forKey: .url)
        guard ReadingLink.problem(with: link) == nil else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: c, debugDescription: "Unsafe link")
        }
        id = try c.decode(UUID.self, forKey: .id)
        title = try ReadingLink.cleanTitle(c.decode(String.self, forKey: .title))
        url = link
        addedOn = try c.decode(DayKey.self, forKey: .addedOn)
        doneOn = try c.decodeIfPresent(DayKey.self, forKey: .doneOn)
    }

    package var displayTitle: String {
        if !title.isEmpty { return title }
        if url.isFileURL { return url.lastPathComponent }
        guard let host = url.host, !host.isEmpty else { return url.absoluteString }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

package enum ReadingAddResult: Error, Equatable, Sendable {
    case added, unsupportedScheme, missingHost, tooLong, duplicate, full
}
