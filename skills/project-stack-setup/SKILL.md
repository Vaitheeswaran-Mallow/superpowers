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
7. **Gitignore** — append four entries to `.gitignore` if not already present (check each line individually before appending)
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
