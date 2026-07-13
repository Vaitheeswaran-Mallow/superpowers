# Question-Driven Stack Setup & Drift Detection

**Date:** 2026-07-13  
**Status:** Approved

---

## Problem

The current `using-project-standards` skill bootstraps `TECH_STACK.md` and `PROJECT_STACK.md` by detecting the stack and copying templates. This produces generic documents without capturing the project's actual architecture decisions. The documents are committed to git (wrong — they're project-specific runtime state, not shared configuration) and there is no changelog tracking who changed them or when. No skill detects when code in a session drifts from the declared stack.

---

## Goals

- Generate stack docs through conversation, not template copy
- Keep stack docs out of git (gitignored) but local to the project
- Track every change with human name + date in a per-doc changelog
- Detect drift from declared stack at natural checkpoints, not on every skill invocation
- Support multiple framework guideline packs (Rails8 now, others later)
- Never expose internal guideline documents to the user

---

## Non-Goals

- Automatic git hooks or cron-based drift scanning
- Multi-project or shared stack docs
- Drift detection mid-session (only at checkpoints)

---

## Architecture

### New Skills

#### `project-stack-setup`
Replaces `using-project-standards`. Triggered by `using-superpowers` when either `docs/TECH_STACK.md` or `docs/PROJECT_STACK.md` is missing.

**Flow:**
1. Agent reads all available guideline packs from `references/standards/` internally — never shown to user
2. Presents user with a plain framework/stack choice (no mention of source docs)
3. Silently reads chosen framework's guideline docs; derives 6–10 targeted questions asked one at a time
4. Generates `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` from answers
5. Appends both files and their changelogs to `.gitignore`
6. Reads human name from `git config user.name`; prompts user if unset
7. Writes initial changelog entry to `docs/TECH_STACK.CHANGELOG.md` and `docs/PROJECT_STACK.CHANGELOG.md`
8. Presents generated docs to user for approval (hard gate — cannot proceed until approved)
9. Hands off to brainstorming

#### `stack-drift-check`
Standalone skill injected at natural checkpoints. Not invoked mid-session.

**Flow:**
1. **Dependency scan** — reads `Gemfile.lock`, `package-lock.json`, `requirements.txt` (whichever exist); compares against libraries in `docs/TECH_STACK.md`; flags unlisted entries
2. **Session usage scan** — reads `git diff main...HEAD`; detects libraries, patterns, or tools referenced in code not present in `docs/TECH_STACK.md`
3. **Decision:** no drift → silent pass. Drift found → present concise list; user chooses to add to stack doc or flag as intentional deviation
4. **Changelog write** — any addition or flagged deviation appended to `docs/TECH_STACK.CHANGELOG.md` with: ISO date, human name (git config), what changed, approved or flagged

### Modified Skills

| Skill | Change |
|---|---|
| `using-superpowers` | Trigger `project-stack-setup` instead of `using-project-standards` when stack docs are missing |
| `finishing-a-development-branch` | Inject `stack-drift-check` before handoff |
| `verification-before-completion` | Inject `stack-drift-check` before sign-off |

### New File Layout

```
references/
  standards/
    rails/          ← Rails8 guideline docs moved here (internal, agent-only)
    node/           ← future
    python/         ← future
docs/
  TECH_STACK.md             ← gitignored, generated
  PROJECT_STACK.md          ← gitignored, generated
  TECH_STACK.CHANGELOG.md   ← gitignored, human-named entries
  PROJECT_STACK.CHANGELOG.md ← gitignored, human-named entries
```

---

## Changelog Format

```markdown
## 2026-07-13 — Jane Smith
**Action:** Initial setup  
**Stack:** Rails 8, DDD-first  
**Notes:** —

## 2026-07-15 — Jane Smith
**Action:** Added `sidekiq` to background jobs section  
**Drift type:** Approved addition  
**Detected at:** finishing-a-development-branch
```

---

## Gitignore Entries

The `project-stack-setup` skill appends these lines to `.gitignore` if not already present:

```
docs/TECH_STACK.md
docs/PROJECT_STACK.md
docs/TECH_STACK.CHANGELOG.md
docs/PROJECT_STACK.CHANGELOG.md
```

---

## Framework Guideline Pack Structure

Each pack lives at `references/standards/<framework>/` and contains one or more markdown files the agent reads silently. No standardized schema is required — the agent derives questions from the content. Rails8 pack is the first; future packs follow the same directory convention.

---

## Key Constraints

- Guideline docs are never shown, quoted, or referenced by name to the user
- Human name is always sourced from `git config user.name` first; only ask if blank
- Drift check is silent on clean pass — no noise when nothing has changed
- Stack docs require human approval before any downstream skill proceeds
- Changelog files are gitignored alongside the stack docs they track
