---
paths:
  - "Sources/SathiCore/Storage/**/*.swift"
  - "Sources/SathiCore/Models/**/*.swift"
  - "Sources/SathiCore/Habits/**/*Prefs.swift"
  - "Sources/SathiCore/Export/JSONExporter.swift"
  - "Sources/SathiCore/Constants/StorageKeys.swift"
  - "Tests/SathiCoreTests/File*Tests.swift"
  - "Tests/SathiCoreTests/LegacyMigrator*Tests.swift"
  - "Tests/SathiCoreTests/LegacyV1Fixture.swift"
  - "Tests/SathiCoreTests/LenientPrefsDecodingTests.swift"
  - "Tests/SathiCoreTests/PrefsCodingTests.swift"
  - "Tests/SathiCoreTests/WholeSecondTests.swift"
  - "Tests/SathiCoreTests/GregorianTests.swift"
  - "Tests/SathiTestSupport/TestFiles.swift"
---

# Storage rules

These rules describe what the storage code does today. Business rules for storage are in `business-logic.md` ("History and storage"). Change that file first when a rule must change. For a new field or a schema bump, follow the `data-migration` skill.

## 1. Layout

The base folder is `~/Library/Application Support/Sathi/` (`AppEnvironment.base`, from `StorageKeys.appFolder`).

| Path | Content | Written by |
|---|---|---|
| `prefs.json` | `Prefs` | `FileStateStore` |
| `state.json` | `LiveState` | `FileStateStore` |
| `history/YYYY-MM.json` | `[HistoryEvent]` of one month | `FileHistoryStore` |
| `migrated-v1` | The text `1`. Not JSON. | `LegacyMigrator` |
| `<file>.corrupt` | A file that did not decode | `JSONFiles` |

- Take every file name, folder name, and suffix from `StorageKeys`. Never write a literal name in code.
- `FileHistoryStore.allEvents()` reads only names that match `StorageKeys.monthFilePattern`.
- The Engine sees only the `StateStore` and `HistoryStore` ports. It never touches a file.

## 2. `schemaVersion`

- `schemaVersion` is in the `Versioned<T>` wrapper in `Storage/JSONFiles.swift`. It is not a field of `Prefs`, `LiveState`, or `HistoryEvent`.
- Every file has the shape `{"schemaVersion": 1, "value": …}`.
- `JSONFiles.write` stamps `Limits.schemaVersion`. Do not stamp a version anywhere else, except the backup export (`JSONExporter`).
- `JSONFiles.load` decodes any version number and does not compare it. A schema bump must add that check first.
- The JSON backup export has its own `schemaVersion` (`Export/JSONExporter.swift`). Keep the two in step.

## 3. Writes

- Write files only through `JSONFiles.write`. It creates the folder and writes with `.atomic`.
- `JSONFiles` encodes dates as ISO 8601 and sorts the keys.
- Saves are coalesced. `savePrefs`, `saveLive`, and `append` mark the value as pending. One write runs after `Timing.saveCoalesce`.
- Each store does all file work on its own serial `DispatchQueue`. Do not touch the cache outside that queue.
- `flush()` writes at once and returns `true` only when nothing is left pending.
- `AppDelegate.applicationWillTerminate` calls `flush()` on both stores. Keep that call when you change the app delegate.
- In tests, pass `delay: 3600` to prove that no file exists before `flush()`.

## 4. Times are whole seconds

- Every stored `Date` goes through `Date.wholeSecond` (`Models/Date+WholeSecond.swift`). ISO 8601 keeps only whole seconds, so memory and disk then hold the same value.
- `HistoryEvent.init` and `HistoryEvent.init(from:)` round the date.
- `LiveState.init(from:)` rounds `lastWaterDone` and `streakReset`.
- The Engine rounds `clock.now` before it stores a time (`Engine+Actions.swift`, `Engine+Export.swift`).
- A new stored `Date` field must round in its `init(from:)` and at the place that sets it.

## 5. Decoding defaults

- Every stored model has a custom `init(from:)` that starts from `Self()` and reads each key with a fallback. `HistoryEvent` is the exception: it decodes `date`, `habit`, and `kind` strictly. See the list of strict fields below.
- Use the helpers in `Models/DecodingDefaults.swift`:
  - `value(_:or:)` for a plain field. A missing key gives the default.
  - `known(_:or:)` for an enum. An unknown raw value gives the default.
  - `knownSet(_:or:keepsEmpty:)` for a set of enums. It drops unknown values.
- Use `known` or `knownSet` for every enum field that a newer version can extend (business rule Schedules 9).
- A key with the wrong JSON type still throws. The whole file then fails and goes to `.corrupt` (rule 6).
- These enum fields use `value`, not `known`, today. An unknown raw value fails the whole file:
  - `strictness` in `WaterPrefs`, `ReadingPrefs`, `MeditationPrefs`.
  - `container` in `WaterPrefs`.
  - `habit` and `kind` in `HistoryEvent` (one bad event fails its month).

## 6. Corrupt and unreadable files

`JSONFiles.load` returns a `LoadResult`:

| File state | Result | What happens |
|---|---|---|
| No file | `.missing` | Defaults load. The next write creates the file. |
| The data cannot be read (for example, no permission) | `.unreadable` | The file is blocked. |
| It reads but does not decode | `.missing` | It is renamed to `<name>.corrupt`, replacing an older `.corrupt` copy. Defaults load. |
| It does not decode and the rename fails | `.unreadable` | The file is blocked. |

- A blocked file is never overwritten. `FileSlot` and `FileHistoryStore` keep a `blocked` flag for the rest of the process.
- A save to a blocked file stays in memory. `load()` and `events(from:to:)` return the in-memory value.
- `FileSlot.write` reads the file once before its first write. A file that was never loaded is still protected.
- An unreadable month returns no events. The other months still load.

## 7. A failed write is kept, then written again

There is no retry timer. The value stays pending until a later write succeeds:

- `FileSlot.write` clears `pending` only after `JSONFiles.write` succeeds.
- `FileHistoryStore.writeDirty` removes a month from `dirty` only after its write succeeds.
- The next save schedules a new coalesced write. The next `flush()` also writes it.
- A blocked file is never retried in the same process.
- `LegacyMigrator` writes no marker when a flush fails, so it runs again at the next launch.

## 8. `LegacyMigrator`

- `AppEnvironment.engine` calls `migrateIfNeeded` at every launch. It stops at once when `migrated-v1` exists.
- It reads the UserDefaults key `StorageKeys.legacyV1`. It does nothing when the key is missing or does not decode.
- It appends only the events that history does not hold yet. A re-run never doubles an event.
- It saves prefs and live state only when `prefs.json` or `state.json` does not exist. It never overwrites newer state.
- It writes the marker only after both stores flush with success.
- It keeps the UserDefaults key as a backup (business rule "History and storage" 7). Removing the key is a later, separate change. Ask the user before you make it.
- Old shapes live in `Storage/Legacy/LegacyV1.swift` and `LegacyV1Prefs.swift`. They decode with defaults too.

## 9. Tests for every storage change

- Write the old JSON as a string fixture in a Swift file, like `Tests/SathiCoreTests/LegacyV1Fixture.swift`. There is no fixtures folder.
- For a new field, add a decode test with JSON that lacks the field (see `LenientPrefsDecodingTests`, `FileStateStoreTests.partialPrefsFileKeepsTheOtherDefaults`).
- For a new enum value, add a test with an unknown raw value. Assert that the other settings stay.
- For a migration, add a re-run test (see `LegacyMigratorRerunTests`, `LegacyMigratorRecoveryTests`).
- For write and read paths, add a permission test (see `FileStateStoreFailureTests`, `FileHistoryStoreFailureTests`).
- Use a new temp folder per test (`makeTempFolder()` in `Tests/SathiTestSupport/TestFiles.swift`).

## 10. Gregorian dates in the user's time zone

- Storage, reports, streaks, and export build their calendar with `Calendar.gregorian(in:)` (`Models/Calendar+Days.swift`).
- Users: `FileHistoryStore`, `ReportBuilder`, `StreakCalculator`, `ReportScreenBuilder`, `ExportNames`.
- Pass the user's calendar in. Keep only its time zone. Never use the system calendar kind for a file name or a range.
- Month file names use the format `%04d-%02d` from Gregorian year and month.
