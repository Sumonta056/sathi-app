import Foundation

package enum StorageKeys {
    package static let legacyV1 = "sathi.state.v1"
    package static let appFolder = "Sathi"
    package static let prefsFile = "prefs.json"
    package static let stateFile = "state.json"
    package static let historyFolder = "history"
    package static let corruptSuffix = ".corrupt"
    package static let migrationMarker = "migrated-v1"
}
