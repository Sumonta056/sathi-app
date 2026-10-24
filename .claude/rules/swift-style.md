---
paths:
  - "**/*.swift"
---

# Swift style

- No comments in code. Names carry the meaning. SwiftLint fails on `//` and `/*`.
- Match the code around you: short names in tight scopes (`p`, `st`, `h`), full names for types and public members.
- One-line bodies are fine: `if x { return y }`, `var id: String { rawValue }`.
- `package` for cross-target API. `private` for helpers used in one file.
- `@MainActor` on every type that touches `Engine`, AppKit, or SwiftUI state.
- Prefer `enum` namespaces for constants and pure functions (`Timing`, `Fmt`, `EscalationPolicy`).
- Prefer value types. Only `Engine`, `StatusModel`, and window controllers are classes.
- Do not add a dependency without asking the user.
- After you edit, the hook runs SwiftFormat and SwiftLint on the file. Fix every error it reports.
