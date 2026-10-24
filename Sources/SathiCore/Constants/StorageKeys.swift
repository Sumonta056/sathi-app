import Foundation

package enum StorageKeys {
    package static let legacyV1 = "sathi.state.v1"
    package static let appFolder = "Sathi"
    package static let prefsFile = "prefs.json"
    package static let stateFile = "state.json"
    package static let historyFolder = "history"
    package static let jsonExtension = ".json"
    package static let monthFilePattern = #"^\d{4}-(0[1-9]|1[0-2])$"#
    package static let exportHistoryPrefix = "Sathi-history-"
    package static let exportBackupPrefix = "Sathi-backup-"
    package static let corruptSuffix = ".corrupt"
    package static let migrationMarker = "migrated-v1"
}
