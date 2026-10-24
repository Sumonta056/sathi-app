---
name: roadmap
description: Show where Sathi is on its roadmap and run the next step. Use when the user types /roadmap, asks "what is next", "where are we", "continue the plan", or when a phase ends and docs/ROADMAP.md must be updated.
---

# /roadmap: keep the work on the plan

The roadmap is `docs/ROADMAP.md`. The business rules are `.claude/rules/business-logic.md`. Both are the source of truth for scope.

## Show status

1. Read `docs/ROADMAP.md`.
2. Report: the current phase, the boxes done, and the next unchecked box.
3. Run `git status` and `git log --oneline -5`. Say if the code and the roadmap do not agree.

## Do the next step

1. Take the next unchecked box. Mark it `[~]`.
2. Read `.claude/rules/business-logic.md`. Check that the step agrees with it. If not, stop and ask the user.
3. Run the `/feature` skill for that step. Do not do more than the step.
4. When tests, lint, and the release build pass, mark the box `[x]`.
5. When every box in a phase is `[x]`, ask the user before the commit for that phase.

## Change the plan

1. A new request that is not on the roadmap: ask the user where it goes (a current phase, a new phase, or Later).
2. Add it to `docs/ROADMAP.md` before any code.
3. A new decision: add a row to the Decisions table with the date.
4. A change to how the app behaves: update `.claude/rules/business-logic.md` first, in the same commit as the code.

## Rules

- Never tick a box without a passing test run.
- Never skip a phase. Phases depend on the ones before them.
- Keep this file and the roadmap short. Move finished detail into the commit message.
