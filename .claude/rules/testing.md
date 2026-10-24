---
paths:
  - "Tests/**/*.swift"
  - "Sources/**/*.swift"
---

# Testing rules

Framework: Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`). UI: ViewInspector 0.10.

## Where tests go

| Code | Test file |
|---|---|
| `Sources/SathiCore/<Folder>/<Name>.swift` | `Tests/SathiCoreTests/<Name>Tests.swift` |
| `Engine+Actions`, `Engine+Loop` | `Tests/SathiCoreTests/EngineFlowTests.swift` |
| `Engine+Display` | `Tests/SathiCoreTests/EngineDisplayTests.swift` |
| `Sources/SathiUI/Features/<Feature>/…` | `Tests/SathiUITests/<Feature>Tests.swift` |
| Fakes and helpers | `Tests/SathiTestSupport/` |

## Patterns

- Build an engine with `EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.… = … }`. It wires fakes and calls `tick()` once.
- Move time with `h.advance(minutes:)`. Never sleep. Never use `Date()` in a test.
- Assert window effects through `h.presenter.calls`, sounds through `h.sound.played`, saves through `h.store.state`.
- UI test: `try View().environmentObject(h.engine).inspect().find(text:)` or `.find(button:).tap()`, then assert on `h.engine`.
- ViewInspector does not run `onAppear` or update `@State` after a tap. Test state-driven branches by building the view in that state, or move the decision into a static function and test it directly (see `ReadingWeekRow.isLit`).
- Use parameterized tests (`@Test(arguments:)`) for tables of inputs.
- Expected values come from the requirement, not from running the code.
- Never weaken or delete a test to make it pass. If the requirement changed, change the test in a separate, explained step.

## Before you say "done"

Run `./scripts/test.sh`. Read the result. Report the real count of passed and failed tests.
