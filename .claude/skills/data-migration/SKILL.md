---
name: data-migration
description: Change what Sathi saves to disk without losing user data. Use when you add a field to Prefs, LiveState, or HistoryEvent, change saved data, rename or remove a stored value, bump the schema (schemaVersion), or write a migration. Also use for the storage step of /add-habit.
---

# /data-migration: change saved data safely

Input: `$ARGUMENTS` is the change to saved data.

Run the `/feature` loop (`.claude/skills/feature/SKILL.md`). Use one recipe below as the plan for its step 2. Read `.claude/rules/storage.md` first.

## What is on disk

Folder: `~/Library/Application Support/Sathi/` (names in `Constants/StorageKeys.swift`).

| File | Type in the file | Store |
|---|---|---|
| `prefs.json` | `Versioned<Prefs>` | `FileStateStore` |
| `state.json` | `Versioned<LiveState>` | `FileStateStore` |
| `history/YYYY-MM.json` | `Versioned<[HistoryEvent]>` | `FileHistoryStore` |
| `migrated-v1` | marker, no JSON | `LegacyMigrator` |

1. `Versioned` (in `Storage/JSONFiles.swift`) wraps every file as `schemaVersion` plus `value`.
2. `JSONFiles.write` stamps `Limits.schemaVersion` (today 1). The backup export (`Export/JSONExporter.swift`) stamps it too.
3. `JSONFiles.load` does not read `schemaVersion` today. It decodes `Versioned<T>`, or moves the file to `.corrupt`.
4. `FileSlot` blocks writes to a file it cannot read. An unreadable file is never overwritten.

## Pick a recipe

- The old JSON still decodes when each new key has a default: use **Add a field**. This is the usual case.
- A key changes its name, type, or meaning, or data moves between files: use **Bump the schema**.
- Ask the user with AskUserQuestion if you are not sure.

## Recipe A: Add a field (no schema bump)

1. Add the property with its default value in the struct (like `MeditationPrefs.chime = true`).
2. Add the key to `CodingKeys`, if the type declares them.
3. Decode the key in `init(from:)` with a helper from `Models/DecodingDefaults.swift`:
   - `value(_:or:)` for plain values.
   - `known(_:or:)` for an enum. An unknown raw value becomes the default.
   - `knownSet(_:or:keepsEmpty:)` for a set of enums. Unknown members are dropped.
4. Encode the key in `encode(to:)`, if the type writes its own encoder.
5. Store dates to the whole second. Use `.wholeSecond` from `Models/Date+WholeSecond.swift`.
6. A new habit adds a struct to `Prefs`, like `meditation`. Decode it with `value(_:or:)` in `Prefs.init(from:)`.

Tests first (`Tests/SathiCoreTests/`):

1. Old JSON without the key decodes to the default. Copy `PrefsCodingTests.swift` ("Prefs coding"), `oneKnownKeyKeepsTheOtherDefaults`.
2. The other settings stay. Copy `FileStateStoreTests.swift`, `partialPrefsFileKeepsTheOtherDefaults`.
3. Encode, then decode, gives the same value. Copy `prefsRoundTrip`.
4. An unknown raw value never resets the other settings. Add a case to `LenientPrefsDecodingTests.swift`.
5. A new date field is whole seconds. Add a case to `WholeSecondTests.swift`.

## Recipe B: Bump the schema

Today no file uses a version other than 1. The first bump adds the version check. Ask the user before you start.

1. Raise `Limits.schemaVersion` in `Constants/Limits.swift`.
2. Keep the old shape as its own type. Copy the style of `Storage/Legacy/LegacyV1.swift` and `LegacyV1Prefs.swift`.
3. Add a function that converts the old shape to the new one. Keep it pure, so a test can call it.
4. In `JSONFiles.load`, read `schemaVersion` first. Decode the old shape when it is lower, then convert.
5. Treat a version higher than `Limits.schemaVersion` as `.unreadable`. Then `FileSlot` never overwrites it.
6. Do not rewrite the file during load. The next normal save writes the new shape atomically.
7. For a one-time move between files, guard it with a marker in `StorageKeys`, like `migrationMarker`.
8. A re-run must never overwrite newer data. Copy the guards in `LegacyMigrator.migrateIfNeeded`.

Tests first:

1. Fixture: put the old file as a Swift string in `Tests/SathiCoreTests/<Name>Fixture.swift`. Copy `LegacyV1Fixture.swift`. There is no resource folder for fixtures.
2. Write the fixture with `writeText` into `makeTempFolder()` (`Tests/SathiTestSupport/TestFiles.swift`). Load it with a real `FileStateStore` or `FileHistoryStore`.
3. Old file loads with every value kept. Compare with an expected value from the requirement.
4. Re-run: load and save twice, or run the migration twice. Assert no lost events and one copy of each. Copy `LegacyMigratorRerunTests.swift` ("LegacyMigrator re-run").
5. No overwrite of newer data. Copy `existingPrefsFileIsNotOverwritten`.
6. Corrupt file: copy `corruptPrefsLoadsDefaultsAndKeepsTheFile` and `corruptMonthFileIsRenamedAndReturnsNoEventsForThatMonth`.
7. Unreadable file: copy `unreadablePrefsFileIsNeverOverwritten` (`FileStateStoreFailureTests.swift`). Restore permissions with `defer`.
8. Newer version: a file with a higher `schemaVersion` is not overwritten.
9. Update the tests that assert `schemaVersion == 1`. Find them with `grep -rn schemaVersion Tests`. Explain each change in the plan.

## Warning: new enum values in history

`HistoryEvent` decodes `habit` and `kind` strictly. An older build cannot decode a month file with a new `HabitID` or `EventKind`. It moves that whole month to `.corrupt`. Tell the user about this downgrade risk in the plan. A new habit (`/add-habit`) always has this risk.

## Finish

1. Run the checks in `CLAUDE.md`, "Definition of done": `./scripts/test.sh`, `./scripts/lint.sh`, `swift build -c release`.
2. Update `.claude/rules/storage.md` if the layout or a storage rule changed.
3. Return to the `/feature` loop for review. Ask before `git commit`.
