---
name: stack-drift-check
description: Detect drift between current code/dependencies and docs/TECH_STACK.md at natural checkpoints — silent when clean; logs approved additions and flagged deviations to changelog
---

# Stack Drift Check

## Overview

Detect libraries, patterns, or tools used in the current session that are absent from `docs/TECH_STACK.md`. Log every resolution to `docs/TECH_STACK.CHANGELOG.md`.

**Silent when clean.** If no drift is found, do not surface this check, do not mention it to the user, and do not add any changelog entries.

## When to Run

Only at natural checkpoints — never mid-session, never at session start:

- Before finishing a development branch (called by `finishing-a-development-branch`)
- Before signing off on verification (called by `verification-before-completion`)

Do NOT run on every skill invocation, at skill start, or mid-task.

## Checklist

Create a todo per item:

1. **Guard** — if `docs/TECH_STACK.md` does not exist in the project repo, skip all remaining steps silently and return
2. **Dependency scan** — read whichever of these exist: `Gemfile.lock`, `package-lock.json`, `requirements.txt`; extract library/gem names; compare each against the entries in `docs/TECH_STACK.md` under "Libraries & tools"; collect names absent from the stack doc
3. **Session usage scan** — run `git diff main...HEAD` (fallback: `git diff HEAD~1...HEAD` when `main` is absent); extract library/gem names, patterns, and tool references from changed files; compare against `docs/TECH_STACK.md`; merge with step 2 results; deduplicate
4. **Clean pass** — if the combined list is empty: silently return; do not mention this check
5. **Present drift** — display: "These were used but aren't in your stack doc:" followed by each item on its own line; for each, ask: (a) add to `TECH_STACK.md`, or (b) mark as intentional deviation?
6. **Apply additions** — for each item the human chose (a): append it to the "Libraries & tools" section of `docs/TECH_STACK.md`
7. **Get human name** — run `git config user.name`; prompt the human for their name if blank
8. **Write changelog** — append one entry per resolved item to `docs/TECH_STACK.CHANGELOG.md`; use the format defined in `skills/project-stack-setup/references/changelog-format.md`; one entry per item, not one bulk entry

## Common Mistakes

- Running this check mid-session or at the start of a skill — only at checkpoints
- Surfacing the check or saying "no drift found" on a clean pass — silent only
- Writing one bulk changelog entry for multiple items — one entry per item
- Skipping the changelog write for approved additions
- Failing to guard when `docs/TECH_STACK.md` is absent
