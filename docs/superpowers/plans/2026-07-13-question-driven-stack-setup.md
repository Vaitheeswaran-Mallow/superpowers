# Question-Driven Stack Setup & Drift Detection — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace template-copy stack bootstrapping with a question-driven skill, add changelog tracking, gitignore the generated docs, and detect stack drift at natural checkpoints.

**Architecture:** A new `project-stack-setup` skill reads framework guideline packs from `references/standards/<framework>/` silently and asks targeted questions; a new `stack-drift-check` skill detects drift at named checkpoints (`finishing-a-development-branch`, `verification-before-completion`). The existing `using-project-standards` skill is deprecated.

**Tech Stack:** Markdown skill files, bash (`git config`, `git diff`), `.gitignore` editing.

## Global Constraints

- Guideline documents in `references/standards/` are NEVER named, quoted, or referenced to the user — agent-only.
- Human name always sourced from `git config user.name` first; only ask if blank.
- Stack docs live at `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` — gitignored.
- Changelogs live at `docs/TECH_STACK.CHANGELOG.md` and `docs/PROJECT_STACK.CHANGELOG.md` — also gitignored.
- Drift check is silent on a clean pass — never surface it when no drift found.
- Drift check runs only at checkpoints, never mid-session.
- One question per message in `project-stack-setup` — never batch questions.

---

### Task 1: Move Rails guideline docs to `references/standards/rails/`

**Files:**
- Create: `references/standards/rails/technical-guideline.md`
- Create: `references/standards/rails/architecture-and-ddd.md`
- Create: `references/standards/rails/ddd-adoption-profiles.md`
- Create: `references/standards/rails/ddd-first-standard.md`
- Delete (via git mv): `Rails8_Technical_Guideline 1.md`, `Architecture_and_DDD_Standard.md`, `Rails8_DDD_Adoption_Profiles.md`, `Rails8_DDD_First_Standard.md`

**Interfaces:**
- Produces: `references/standards/rails/` directory with four guideline docs, discoverable by `project-stack-setup`

- [ ] **Step 1: Create the target directory**

```bash
mkdir -p references/standards/rails
```

- [ ] **Step 2: Move the four docs using git mv**

```bash
git mv "Rails8_Technical_Guideline 1.md" references/standards/rails/technical-guideline.md
git mv Architecture_and_DDD_Standard.md references/standards/rails/architecture-and-ddd.md
git mv Rails8_DDD_Adoption_Profiles.md references/standards/rails/ddd-adoption-profiles.md
git mv Rails8_DDD_First_Standard.md references/standards/rails/ddd-first-standard.md
```

- [ ] **Step 3: Verify directory structure**

```bash
ls references/standards/rails/
```

Expected output:
```
architecture-and-ddd.md
ddd-adoption-profiles.md
ddd-first-standard.md
technical-guideline.md
```

- [ ] **Step 4: Verify the old files are gone from root**

```bash
ls *.md
```

Expected: `Architecture_and_DDD_Standard.md`, `Rails8_*` are NOT in the output (only `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `README.md`, `CODE_OF_CONDUCT.md`, `RELEASE-NOTES.md` remain).

- [ ] **Step 5: Commit**

```bash
git add references/standards/rails/
git commit -m "move: Rails8 guideline docs to references/standards/rails/"
```

---

### Task 2: Create `skills/project-stack-setup/` skill

**Files:**
- Create: `skills/project-stack-setup/SKILL.md`
- Create: `skills/project-stack-setup/references/changelog-format.md`

**Interfaces:**
- Consumes: `references/standards/<framework>/` files (silently)
- Produces: `docs/TECH_STACK.md`, `docs/PROJECT_STACK.md`, `docs/TECH_STACK.CHANGELOG.md`, `docs/PROJECT_STACK.CHANGELOG.md` (in the project repo at invocation time); `.gitignore` entries

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p skills/project-stack-setup/references
```

- [ ] **Step 2: Write changelog-format.md**

Write the following to `skills/project-stack-setup/references/changelog-format.md`:

```markdown
# Stack Document Changelog Format

Append one entry per change. Most recent entry at the bottom.

## Entry structure

```
## YYYY-MM-DD — <Human Name>
**Action:** <Initial setup | Added <item> | Removed <item> | Flagged deviation: <item>>
**Drift type:** <N/A | Approved addition | Intentional deviation>
**Detected at:** <N/A | finishing-a-development-branch | verification-before-completion>
**Notes:** <optional context, or — if none>
```

## Examples

```
## 2026-07-13 — Jane Smith
**Action:** Initial setup
**Drift type:** N/A
**Detected at:** N/A
**Notes:** Rails 8, Pragmatic DDD, 3 bounded contexts

## 2026-07-15 — Jane Smith
**Action:** Added `sidekiq` to Libraries & tools
**Drift type:** Approved addition
**Detected at:** finishing-a-development-branch
**Notes:** Background job processing for async report generation

## 2026-07-18 — Jane Smith
**Action:** Flagged deviation: `faraday` (used but not in stack doc)
**Drift type:** Intentional deviation
**Detected at:** verification-before-completion
**Notes:** One-off external call in spike; will revisit in next iteration
```
```

- [ ] **Step 3: Write SKILL.md**

Write the following to `skills/project-stack-setup/SKILL.md`:

```markdown
---
name: project-stack-setup
description: Use when docs/TECH_STACK.md or docs/PROJECT_STACK.md is missing — question-driven stack document generation from internal guideline packs; hard gate before feature work
---

# Project Stack Setup

## Overview

Bootstrap `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` through conversation. Reads internal guideline packs silently to derive targeted questions — never names, quotes, or exposes them to the user.

**Announce at start:** "I'm using the project-stack-setup skill to set up your project stack."

<HARD-GATE>
Do NOT invoke brainstorming, writing-plans, or test-driven-development until this skill completes and the human approves both stack documents.
</HARD-GATE>

## Checklist

Create a todo per item:

1. **Discover stacks** — list directories under `references/standards/`; build a display-name map (e.g. `rails` → "Rails 8", `node` → "Node/Express", `python` → "Python/Django")
2. **Ask framework** — present display names only; ask which stack the project uses; do not mention guideline docs, source files, or directory names
3. **Read guideline pack** — silently read every file under `references/standards/<chosen>/`; derive 6–10 questions from the content; never quote or name a source file to the user
4. **Ask questions one at a time** — required questions: product summary, core user loop, user roles, architecture mode, key entities (2–5), enabled add-ons, verify command, out-of-scope items; for DDD modes also ask: bounded contexts with subdomain classification (Core / Supporting / Generic)
5. **Generate TECH_STACK.md** — write `docs/TECH_STACK.md` from answers using the format below
6. **Generate PROJECT_STACK.md** — write `docs/PROJECT_STACK.md` from answers using the format below
7. **Gitignore** — append four entries to `.gitignore` if not already present (see Gitignore section below)
8. **Human name** — run `git config user.name`; if blank, ask: "What name should we use for the changelog?"
9. **Write changelogs** — create `docs/TECH_STACK.CHANGELOG.md` and `docs/PROJECT_STACK.CHANGELOG.md` with a single initial entry each; see [changelog-format.md](references/changelog-format.md)
10. **Human approval** — present both docs; hard stop until the human approves; revise on request
11. **Hand off** — invoke brainstorming for the first feature, or wait if the human has not asked to build yet

## TECH_STACK.md Format

```markdown
# Tech Stack

## Stack
<framework name>

## Architecture mode
<none | ddd-companion | ddd-first>

## Standards reference
<relative path(s) to internal standard docs — e.g. references/standards/rails/>

## Verify command
<e.g. bin/ci or npm test>

## Libraries & tools
<bulleted list of key libraries/gems, one per line, derived from add-ons and answers>

## Norms & safeguards (summary)
See `.cursor/rules/` and `references/standards/<stack>/`
```

## PROJECT_STACK.md Format

```markdown
# Project Stack

## Product summary
<one paragraph: what the app does and for whom>

## Core user loop
<e.g. sign up → onboard → primary action → outcome>

## Roles
<list roles; note whether each is fixed or mutable>

## Architecture mode
<none | ddd-companion | ddd-first>

## Entity catalog

| Entity | Module/Context | Description |
|--------|----------------|-------------|
| | | |

## Bounded contexts
<!-- populate when architecture mode is ddd-companion or ddd-first -->

| Context | Subdomain | Owner | Profile | ADR |
|---------|-----------|-------|---------|-----|
| | | | | |

## Enabled add-ons
<!-- list each enabled add-on and its ADR link -->

## Out of scope
<!-- explicit exclusions for this phase -->

## Open TBCs / assumptions
<!-- decisions pending product, legal, or ops confirmation -->
```

## Gitignore Entries

Append to `.gitignore` if not already present — check for each line individually before appending:

```
# Project stack docs (local only — not shared via git)
docs/TECH_STACK.md
docs/PROJECT_STACK.md
docs/TECH_STACK.CHANGELOG.md
docs/PROJECT_STACK.CHANGELOG.md
```

## When NOT to Use

- Both `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` already exist and are current
- Pure questions with no implementation intent

## Common Mistakes

- Naming or quoting internal guideline documents to the user — they must remain invisible
- Asking multiple questions in one message — one question per message, always
- Skipping human approval on the generated docs
- Forgetting to gitignore the changelog files alongside the stack docs
- Generating a generic doc from memory instead of deriving content from actual answers
- Appending duplicate .gitignore entries — check each line first
```

- [ ] **Step 4: Verify frontmatter is valid**

```bash
head -5 skills/project-stack-setup/SKILL.md
```

Expected output — must contain `name:` and `description:` between the `---` fences:
```
---
name: project-stack-setup
description: Use when docs/TECH_STACK.md or docs/PROJECT_STACK.md is missing ...
---
```

- [ ] **Step 5: Verify changelog-format.md exists and has examples**

```bash
grep -c "## 20" skills/project-stack-setup/references/changelog-format.md
```

Expected: `3` (three example entries)

- [ ] **Step 6: Commit**

```bash
git add skills/project-stack-setup/
git commit -m "feat: add project-stack-setup skill — question-driven stack doc generation"
```

---

### Task 3: Update `using-superpowers` to trigger `project-stack-setup`

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` lines 101–109

**Interfaces:**
- Consumes: `skills/project-stack-setup/SKILL.md` (name reference)
- Produces: updated trigger rule in the orchestration skill

- [ ] **Step 1: Open and read the current Skill Priority section**

Read `skills/using-superpowers/SKILL.md` lines 100–124 to confirm current content before editing.

- [ ] **Step 2: Replace the Skill Priority section**

In `skills/using-superpowers/SKILL.md`, replace:

```markdown
## Skill Priority

When multiple skills could apply, use this order:

1. **Project bootstrap first** (`using-project-standards`) — when `docs/TECH_STACK.md` or `docs/PROJECT_STACK.md` is missing and the user wants to build or scaffold
2. **Process skills second** (brainstorming, systematic-debugging) — these determine HOW to approach the task
3. **Implementation skills third** (frontend-design, mcp-builder) — these guide execution

"Let's build X" in a repo without stack files → `using-project-standards` first, then brainstorming, then implementation skills.
"Let's build X" with stack files ready → brainstorming first, then implementation skills.
"Fix this bug" → systematic-debugging first, then domain-specific skills.
```

With:

```markdown
## Skill Priority

When multiple skills could apply, use this order:

1. **Project bootstrap first** (`project-stack-setup`) — when `docs/TECH_STACK.md` or `docs/PROJECT_STACK.md` is missing and the user wants to build or scaffold
2. **Process skills second** (brainstorming, systematic-debugging) — these determine HOW to approach the task
3. **Implementation skills third** (frontend-design, mcp-builder) — these guide execution

"Let's build X" in a repo without stack files → `project-stack-setup` first, then brainstorming, then implementation skills.
"Let's build X" with stack files ready → brainstorming first, then implementation skills.
"Fix this bug" → systematic-debugging first, then domain-specific skills.
```

- [ ] **Step 3: Verify the change**

```bash
grep "project-stack-setup" skills/using-superpowers/SKILL.md
```

Expected: 2 lines — one in the numbered list, one in the examples.

```bash
grep "using-project-standards" skills/using-superpowers/SKILL.md
```

Expected: no output (old reference fully removed).

- [ ] **Step 4: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "feat: route stack bootstrap to project-stack-setup in using-superpowers"
```

---

### Task 4: Create `skills/stack-drift-check/` skill

**Files:**
- Create: `skills/stack-drift-check/SKILL.md`

**Interfaces:**
- Consumes: `docs/TECH_STACK.md` (in the project repo at invocation time), `Gemfile.lock` / `package-lock.json` / `requirements.txt`, `git diff main...HEAD`
- Consumes: `skills/project-stack-setup/references/changelog-format.md` (format reference)
- Produces: updated `docs/TECH_STACK.md`, new entries appended to `docs/TECH_STACK.CHANGELOG.md`

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/stack-drift-check
```

- [ ] **Step 2: Write SKILL.md**

Write the following to `skills/stack-drift-check/SKILL.md`:

```markdown
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
8. **Write changelog** — append one entry per resolved item to `docs/TECH_STACK.CHANGELOG.md`; use the format defined in `skills/project-stack-setup/references/changelog-format.md`; do not write a bulk entry

## Common Mistakes

- Running this check mid-session or at the start of a skill (only at checkpoints)
- Surfacing the check or saying "no drift found" on a clean pass — silent only
- Writing one bulk changelog entry for multiple items — one entry per item
- Skipping the changelog write for approved additions
- Failing to guard when `docs/TECH_STACK.md` is absent
```

- [ ] **Step 3: Verify frontmatter**

```bash
head -5 skills/stack-drift-check/SKILL.md
```

Expected:
```
---
name: stack-drift-check
description: Detect drift between current code/dependencies and docs/TECH_STACK.md ...
---
```

- [ ] **Step 4: Commit**

```bash
git add skills/stack-drift-check/
git commit -m "feat: add stack-drift-check skill — detect stack drift at natural checkpoints"
```

---

### Task 5: Inject `stack-drift-check` into `finishing-a-development-branch`

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`

**Interfaces:**
- Consumes: `skills/stack-drift-check/SKILL.md` (name reference)
- Produces: drift check runs before the finish-branch options are presented

- [ ] **Step 1: Read the skill to confirm insertion point**

Read `skills/finishing-a-development-branch/SKILL.md`. The insertion point is the success path of Step 1 (after "If tests pass: Continue to Step 2."). Drift check runs here — after tests pass, before presenting options.

- [ ] **Step 2: Replace the Step 1 success path**

In `skills/finishing-a-development-branch/SKILL.md`, replace:

```markdown
**If tests pass:** Continue to Step 2.
```

With:

```markdown
**If tests pass:** Run `stack-drift-check` skill. Once drift check completes (or passes silently), continue to Step 2.
```

- [ ] **Step 3: Verify the change**

```bash
grep "stack-drift-check" skills/finishing-a-development-branch/SKILL.md
```

Expected: 1 line containing `stack-drift-check`.

- [ ] **Step 4: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "feat: inject stack-drift-check before finish-branch options"
```

---

### Task 6: Inject `stack-drift-check` into `verification-before-completion`

**Files:**
- Modify: `skills/verification-before-completion/SKILL.md`

**Interfaces:**
- Consumes: `skills/stack-drift-check/SKILL.md` (name reference)
- Produces: drift check runs as part of the verification gate

- [ ] **Step 1: Read the skill to find the right injection point**

Read `skills/verification-before-completion/SKILL.md`. The Gate Function section lists five steps. Drift check belongs as a new step 0, before step 1 ("IDENTIFY"), so it runs before any completion claim is assembled.

- [ ] **Step 2: Replace The Gate Function section**

In `skills/verification-before-completion/SKILL.md`, replace:

```markdown
## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```
```

With:

```markdown
## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

0. STACK DRIFT: If docs/TECH_STACK.md exists, run stack-drift-check skill first.
   Resolve any drift before proceeding. Skip silently if no drift.
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```
```

- [ ] **Step 3: Verify the change**

```bash
grep "stack-drift-check" skills/verification-before-completion/SKILL.md
```

Expected: 1 line containing `stack-drift-check`.

- [ ] **Step 4: Verify step numbering is intact**

```bash
grep -E "^[0-9]\." skills/verification-before-completion/SKILL.md
```

Expected: lines `0. STACK DRIFT`, `1. IDENTIFY`, `2. RUN`, `3. READ`, `4. VERIFY`, `5. ONLY THEN`.

- [ ] **Step 5: Commit**

```bash
git add skills/verification-before-completion/SKILL.md
git commit -m "feat: inject stack-drift-check into verification gate"
```

---

### Task 7: Deprecate `using-project-standards`

**Files:**
- Modify: `skills/using-project-standards/SKILL.md`

**Interfaces:**
- Produces: clear deprecation notice directing users to `project-stack-setup`

- [ ] **Step 1: Read the current skill header**

Read `skills/using-project-standards/SKILL.md` lines 1–15 to see the frontmatter and first section.

- [ ] **Step 2: Add deprecation notice after the frontmatter**

In `skills/using-project-standards/SKILL.md`, replace:

```markdown
# Using Project Standards

## Overview
```

With:

```markdown
# Using Project Standards

> **Deprecated.** This skill has been replaced by `project-stack-setup`, which generates stack documents through targeted questions rather than template copy. Use `project-stack-setup` for all new projects. `using-project-standards` is kept here for reference only and will not be updated.

## Overview
```

- [ ] **Step 3: Verify the deprecation notice is present**

```bash
grep "Deprecated" skills/using-project-standards/SKILL.md
```

Expected: 1 line containing "Deprecated" and "project-stack-setup".

- [ ] **Step 4: Commit**

```bash
git add skills/using-project-standards/SKILL.md
git commit -m "deprecate: using-project-standards — superseded by project-stack-setup"
```

---

## Self-Review Checklist

### Spec coverage

| Spec requirement | Covered by task |
|---|---|
| Rails guideline docs moved to `references/standards/rails/` | Task 1 |
| Docs never revealed to user | Task 2 — skill instructs agent to read silently |
| Question-driven setup from chosen guideline | Task 2 — SKILL.md checklist steps 2–4 |
| `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` gitignored | Task 2 — step 7 + gitignore section |
| Human name from git config | Task 2 — step 8; Task 4 — step 7 |
| Changelog with human-name entries | Task 2 + Task 4 — changelog-format.md + checklist step 9 / step 8 |
| Human approval before proceeding | Task 2 — step 10 HARD-GATE |
| Brainstorm handoff after setup | Task 2 — step 11 |
| Dependency scan for drift (B) | Task 4 — checklist step 2 |
| Session usage scan for drift (A) | Task 4 — checklist step 3 |
| Silent pass when no drift | Task 4 — checklist step 4 |
| Drift at checkpoints only | Task 5 + Task 6 |
| `using-superpowers` triggers new skill | Task 3 |
| `using-project-standards` deprecated | Task 7 |
| Extensible to multiple framework packs | Task 1 — `references/standards/<framework>/` pattern; Task 2 — discover step reads the directory |

No gaps found.
