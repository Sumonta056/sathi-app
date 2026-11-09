import Foundation

package enum ActivityCategoryList {
    package static func cleanName(_ raw: String) -> String? {
        let joined = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        let cut = String(trimmed.prefix(Limits.categoryNameMax)).trimmingCharacters(in: .whitespaces)
        return cut.isEmpty ? nil : cut
    }

    package static func adding(_ raw: String, colorHex: UInt32, to list: [ActivityCategory]) -> [ActivityCategory]? {
        guard list.count < Limits.categoryMax, let name = cleanName(raw), index(of: name, in: list) == nil else { return nil }
        return list + [ActivityCategory(name: name, colorHex: colorHex)]
    }

    package static func renaming(_ old: String, to raw: String, in list: [ActivityCategory]) -> [ActivityCategory]? {
        guard let i = list.firstIndex(where: { $0.name == old }), let name = cleanName(raw) else { return nil }
        if let taken = index(of: name, in: list), taken != i { return nil }
        var next = list
        next[i].name = name
        return next
    }

    package static func removing(_ name: String, from list: [ActivityCategory]) -> [ActivityCategory] {
        list.filter { $0.name != name }
    }

    package static func recoloring(_ name: String, to colorHex: UInt32, in list: [ActivityCategory]) -> [ActivityCategory] {
        list.map { $0.name == name ? ActivityCategory(name: name, colorHex: colorHex) : $0 }
    }

    private static func index(of name: String, in list: [ActivityCategory]) -> Int? {
        list.firstIndex { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
