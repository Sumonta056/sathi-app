---
name: feature
description: The required loop for every change to Sathi. Use for any new feature, bug fix, UI tweak, or behavior change, and whenever the user types /feature <description>. Plan, get approval, write failing tests, implement, check lint/tests/perf, review, then ask before committing.
---

# /feature: plan, red, green, check, review

Run these steps in order. Do not skip a step.

Input: `$ARGUMENTS` is the request. If it is empty or vague, ask the user with AskUserQuestion before step 1.

## 1. Read

1. Read `CLAUDE.md`.
2. Read the files you plan to change and their tests (see the table in `.claude/rules/testing.md`).
3. Find which layer owns the change (`.claude/rules/architecture.md`, "Where new code goes").

## 2. Plan and get approval

Write a short plan:

- Goal in one sentence.
- Files to add or change, with `file:line`.
- Tests to add or change, and the behavior each test checks.
- New constants, and the Constants file each one goes in.
- Performance impact: new timers, animations, or published state? If yes, say how you keep the budget.
- Risks and open questions.

Ask for approval with AskUserQuestion: "Approve", "Change the plan", "Stop". Write no code before approval.

## 3. Red: failing tests first

1. Spawn the `test-writer` agent with the approved plan and the test paths. Tell it the code does not exist yet.
2. Run the new tests: `./scripts/test.sh "<Suite name>"`.
3. Check that each test fails for the right reason (missing behavior or wrong value). A compile error in the test file is not red. Send it back.

## 4. Green: implement

1. Write the smallest code that makes the tests pass.
2. Keep files under 200 lines. Split by job before you reach the limit.
3. No comments. No magic numbers. No `Date()` in Core logic.

## 5. Check

Run all of these and read the output:

```
./scripts/lint.sh
./scripts/test.sh
swift build -c release
```

If the change touches timers, animations, `@Published` state, or windows, also run the `/perf-check` skill.

## 6. Review

Spawn the `code-reviewer` agent on the diff (`git diff`). Fix every finding it marks as a blocker. Tell the user about the rest.

## 7. Finish

1. Update `README.md` and `CLAUDE.md` if commands, modules, or rules changed.
2. Report: what changed (`file:line`), test count, lint result, perf numbers if measured.
3. Ask before `git commit`. Never commit to `main`.
