# Phase 5g2: Lock screen and legacy views on Night, delete `Palette`

Goal: no view uses the old light `Palette`. The Lock screen, the pill buttons, and the legacy reading-focus views (`LegacyBubble`, `ReadingInfoCard`, `SessionView`, `LegacyCelebrate`, `CelebrateRows`) use `Night`. The buddy drawings keep their exact colors in a new `BuddyInk`. `Theme/Palette.swift` is deleted.

No behavior change. All texts, buttons, and actions stay the same. Only colors, and the move of literal sizes to `UIMetrics`.

User choice (2026-10-25): a separate slice before 5h; the legacy views get the Night theme, not a new layout.

## Part 1: `BuddyInk` (`Buddy/BuddyInk.swift`)

The character art colors move from `Palette` with the same hex values:

| Name | Hex |
|---|---|
| `line` (was `ink`, used by the pebble face) | `0x0D1B2A` |
| `water` | `0x1FA8E6` |
| `waterDeep` | `0x0B5F9E` |
| `waterPale` | `0xDCF2FC` |
| `waterMid` | `0x7FD3F5` |
| `waterGlass` | `0xEEF8FD` |
| `waterDrained` | `0xBFE8FA` |
| `outline` | `0x0B4F86` |
| `drip` | `0x8FD8F7` |
| `cover` | `0xF2A33A` |
| `spine` | `0xD9822B` |
| `pages` | `0xFFF6E2` |
| `bookLine` | `0x7A420F` |
| `ribbon` | `0xE0473C` |
| `cheek` | `0xFF9FB8` |
| `spark` | `0xFFC94A` |

`BuddyCanvas`, `BuddyCanvas+Pebble`, and `WaterInk` use `BuddyInk`. Any other `Palette` color that a drawing needs goes in `BuddyInk` with its old hex.

## Part 2: `PillButton` (`Theme/ButtonStyles.swift`)

Add `static func colors(_ kind: Kind) -> (fg: Color, bg: Color)`:

| Kind | Foreground | Background |
|---|---|---|
| `primary` | `Night.onAccent` | `Night.sprout` |
| `ghost` | `Night.text` | `Night.text.opacity(UIMetrics.ghostFillOpacity)` |
| `onDark` | `Night.onAccent` | `Night.water` |
| `danger` | `Night.cheek` | `Night.text.opacity(UIMetrics.ghostFillOpacity)` |

`ghostFillOpacity` = 0.08. Literal sizes (14, 12, 0.8) move to `UIMetrics`.

## Part 3: Lock screen (`Features/Lock/`)

| Old | New |
|---|---|
| `Palette.night` (shade and background) | `Night.sidebar` |
| `Palette.waterMid` (label, hold ring) | `Night.waterLine` |
| `Palette.lockBody` (instructions) | `Night.chipText` |
| `Palette.lockHint` (hints, skip area) | `Night.muted` |
| `.white` (main text) | `Night.text` |

Fonts become `Typography` where a matching style exists. Literal sizes, spacings, and the shade opacity (0.9) move to a new `UIMetrics+Lock.swift`. The 30 fps `TimelineView` stays.

## Part 4: Legacy reading-focus views

Dark cards like the 5d/5e cards:

| Old | New |
|---|---|
| `Palette.card`, `Palette.paper` (card fill) | `Night.card` |
| `Color.black.opacity(0.08)` (card border) | `Night.border` |
| `Palette.ink`, `Palette.ink2` (text) | `Night.text`, `Night.muted` |
| `Palette.muted` | `Night.muted` |
| `Palette.accent(id)` | `Night.accent(id)` |
| `Palette.deep(id)`, `Palette.calmDeep`, `Palette.bookDeep` (labels) | `Night.accent(id)` |
| `Palette.bookCard` (reading info fill) | `Night.heroFill(.reading)`, border `Night.heroBorder(.reading)` |
| `Palette.water`, `Palette.waterDeep` (the "Fota is waiting" chip) | `Night.water` text on `Night.heroFill(.water)` |
| `Palette.book` (celebrate rows) | `Night.reading` |
| `IgnoreBar` track `Color.black.opacity(0.08)` | `Night.border` |

Each view that can show alone in a panel sets `.environment(\.colorScheme, .dark)`.

## Part 5: Delete

- `Sources/SathiUI/Theme/Palette.swift`.
- `grep -rn "Palette\." Sources` returns nothing (it must not match `NightPalette` file names or `Night`).

## Tests that define done

1. `BuddyInk` holds each hex of the table (pins the art colors; compare with `Color(hex:)`).
2. `PillButton.colors` returns the table pair for each of the 4 kinds.
3. Lock: `LockView` still shows "SNOOZED TWICE · SCREEN PAUSED", each habit headline, and "Press and hold." (existing tests stay green).
4. Legacy views: the existing tests for `LegacyBubble`, `SessionView`, `LegacyCelebrate`, and `ReadingInfoCard` stay green with no change to their asserted strings.
5. A source scan test: no file under `Sources/` contains the text `Palette.`, and `Sources/SathiUI/Theme/Palette.swift` does not exist. (Use `#filePath` to find the repo root.)
