# Phase 5a: Theme and shared parts

Goal: the "Night sprout" tokens, SF Rounded type, and the shared views that slices 5b–5g build on. No existing screen changes in this slice. The old light `Palette` stays until slice 5g, then it is deleted.

Design: https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (Settings artboard, `Main.dc.html`).

All new types are `internal` in `SathiUI`. Tests use `@testable import SathiUI`. No Engine calls in this slice.

## `Theme/NightPalette.swift`

```swift
enum Night {
    static let bg: Color          // #121826
    static let sidebar: Color     // #0D1220
    static let card: Color        // #1A2233
    static let border: Color      // #263049
    static let divider: Color     // #222B40
    static let text: Color        // #EEF2FA
    static let muted: Color       // #9AA6BF
    static let label: Color       // #8C99B3
    static let faint: Color       // #7784A0  (canvas #6F7C97 fails 4.5:1; never on a card)
    static let water: Color       // #4CC3F5
    static let reading: Color     // #F2A64A
    static let calm: Color        // #A99CF5
    static let sprout: Color      // #5FD39A
    static let cheek: Color       // #FF9FB8
    static let spark: Color       // #FFC94A
    static let onAccent: Color    // #0D1220  text on an accent fill
    static let switchOff: Color   // #3A4458
    static let fieldBorder: Color // #2C3650  chip and field border when not selected
    static let chipText: Color    // #C9D2E3  chip text when not selected
    static let navSelected: Color // #1E2840
    static let calmGround: Color  // #16142A

    static func accent(_ id: HabitID) -> Color      // water / reading / calm
    static func heroFill(_ id: HabitID) -> Color    // #15263A / #2A2219 / #211F38
    static func heroBorder(_ id: HabitID) -> Color  // #1F3D5A / #4A3720 / #37335C
}
```

Every `switch` on `HabitID` is exhaustive, with no `default:`.

### Contrast pairs (each ≥ 4.5:1, WCAG relative luminance)

- `text`, `muted`, `label`, `chipText` on `bg`, `sidebar`, `card`.
- `faint` on `bg` and `sidebar` only.
- `accent(id)` for every habit, and `sprout`, on `bg`, `sidebar`, `card`.
- `onAccent` on `accent(id)` for every habit and on `sprout`.
- `muted` on `heroFill(id)` for every habit.

## `Theme/Typography.swift`

```swift
enum Typography {
    static let title: Font         // 24, .black
    static let heroTitle: Font     // 20, .black
    static let rowLabel: Font      // 14, .heavy
    static let hint: Font          // 12, .semibold
    static let chip: Font          // 13, .heavy
    static let sectionLabel: Font  // 11, .black
    static let eyebrow: Font       // 12, .black
}
```

Every font is `.system(size:weight:design: .rounded)`. Sizes and the tracking value go in `UIMetrics`.

## `Constants/UIMetrics+Components.swift`

`extension UIMetrics` with:

| Name | Value |
|---|---|
| `cardRadius` | 16 |
| `optionRadius` | 14 |
| `buttonRadius` | 10 |
| `chipHeight` | 32 |
| `chipPadding` | 13 |
| `chipSpacing` | 8 |
| `chipBorder` | 1.5 |
| `chipFillOpacity` | 0.15 |
| `optionFillOpacity` | 0.10 |
| `optionGlowOpacity` | 0.2 |
| `optionGlowRadius` | 10 |
| `optionPadding` | 14 |
| `switchSize` | 40 × 22 |
| `switchKnob` | 18 |
| `switchSpringResponse` | 0.3 |
| `switchSpringDamping` | 0.55 |
| `rowPadding` | `EdgeInsets` 14 vertical, 18 horizontal |
| `heroPadding` | `EdgeInsets` 18 vertical, 20 horizontal |
| `heroSpacing` | 18 |
| `labelTracking` | 1 |
| `fontTitle`, `fontHeroTitle`, `fontRowLabel`, `fontHint`, `fontChip`, `fontSectionLabel`, `fontEyebrow` | 24, 20, 14, 12, 13, 11, 12 |

## Components (`Sources/SathiUI/Components/`, one view per file)

### `SectionLabel`

`SectionLabel(_ text: String)`. Shows `text.uppercased()` in `Typography.sectionLabel`, color `Night.label`, tracking `labelTracking`.

### `ChipRow<Value: Hashable>`

```swift
ChipRow(
    options: [Value],
    accent: Color,
    isSelected: @escaping (Value) -> Bool,
    onTap: @escaping (Value) -> Void,
    label: @escaping (Value) -> String
)
```

- One `Button` per option, in order. The button text is `label(value)`.
- Tap calls `onTap(value)`. The row has no selection state of its own, so the same view does single select and multi select.
- Selected chip: accent border, accent fill at `chipFillOpacity`, accent text, accessibility trait `.isSelected`.
- Chip that is not selected: `fieldBorder` border, clear fill, `chipText` text, no `.isSelected` trait.
- Pill shape, height `chipHeight`.

### `OptionCard<Top: View>`

```swift
OptionCard(
    title: String,
    detail: String,
    isSelected: Bool,
    accent: Color,
    action: @escaping () -> Void,
    @ViewBuilder top: () -> Top
)
```

- One `Button`. Inside: `top`, then the title (`rowLabel`, `text`), then the detail (`hint`, `muted`).
- Selected: accent border, accent fill at `optionFillOpacity`, accent shadow. Not selected: `border` border, `card` fill.
- Selected adds the trait `.isSelected`.
- Corner radius `optionRadius`.

### `BuddySwitch`

`BuddySwitch(isOn: Binding<Bool>, accent: Color, label: String)`

- One `Button`. A tap flips `isOn`.
- Track `switchSize`, pill shape, fill `accent` when on, `switchOff` when off. White knob `switchKnob`, at the right when on.
- The knob moves with `.spring(response:dampingFraction:)` from `UIMetrics`. When `accessibilityReduceMotion` is on, no animation.
- Accessibility: label `label`, trait `.isSelected` when on, value "On" or "Off".

### `HeroCard<Buddy: View>`

```swift
HeroCard(
    habit: HabitID,
    eyebrow: String,
    title: String,
    hint: String,
    isOn: Binding<Bool>,
    switchLabel: String,
    @ViewBuilder buddy: () -> Buddy
)
```

- `HStack`: `buddy`, then a column with the eyebrow (`Typography.eyebrow`, `Night.accent(habit)`), title (`heroTitle`, `text`), hint (`hint`, `muted`), then a `BuddySwitch(isOn:accent: Night.accent(habit), label: switchLabel)`.
- Fill `Night.heroFill(habit)`, border `Night.heroBorder(habit)`, radius `cardRadius`, padding `heroPadding`.

### `SettingsCard` and `SettingRow`

```swift
SettingsCard<Content: View>(@ViewBuilder content: () -> Content)
SettingRow<Trailing: View>(label: String, hint: String? = nil, @ViewBuilder trailing: () -> Trailing)
```

- `SettingsCard`: a `VStack(spacing: 0)` of its rows on `Night.card`, border `Night.border`, radius `cardRadius`.
- `SettingRow`: label (`rowLabel`, `text`), optional hint below it (`hint`, `muted`), `Spacer`, `trailing`. Padding `rowPadding`. Rows after the first show a `Night.divider` line at the top: `SettingRow` takes `showsDivider: Bool = true`, and the first row of a card passes `false`.

## Tests that define done

UI tests in `Tests/SathiUITests/` (ViewInspector, `@MainActor`):

1. `Night` contrast: every pair in the list above is ≥ 4.5:1. Convert with `NSColor(color).usingColorSpace(.sRGB)`. A test helper computes the ratio.
2. `Night.accent`, `heroFill`, `heroBorder` return the hex values above for each `HabitID` (check sRGB components to 1/255).
3. `SectionLabel("Daily goal")` shows the text "DAILY GOAL".
4. `ChipRow` shows one button per option with `label(value)` text, in order.
5. `ChipRow` tap on "30 min" calls `onTap(30)` once.
6. `ChipRow` gives the `.isSelected` trait only to chips where `isSelected` is true (multi select: two of three selected).
7. `OptionCard` shows title and detail; tap calls `action`; `.isSelected` trait follows `isSelected`.
8. `BuddySwitch` tap flips the binding from false to true and back.
9. `BuddySwitch` has the accessibility label it was given, and value "On" / "Off".
10. `HeroCard` shows eyebrow, title, and hint, and holds a `BuddySwitch` with the `switchLabel`. A tap on it flips `isOn`.
11. `SettingRow` shows label and hint; without a hint it shows only the label; it shows the `trailing` view.
12. `SettingsCard` shows its rows.

All old tests keep passing. No file over 200 lines. No comments.
