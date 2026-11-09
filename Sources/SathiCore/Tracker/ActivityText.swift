import Foundation

package enum ActivityText {
    package static func clean(_ raw: String) -> String? {
        let joined = String(raw.map { $0.isNewline ? " " : $0 })
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        let cut = String(trimmed.prefix(Limits.activityTextMax)).trimmingCharacters(in: .whitespaces)
        return cut.isEmpty ? nil : cut
    }
}
