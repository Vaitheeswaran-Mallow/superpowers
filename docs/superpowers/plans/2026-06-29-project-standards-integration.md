# Project Standards Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add generic project bootstrap (`using-project-standards`), stack-aware templates, Rails8 reference packs, and skill extensions (entity impact, DDD applicability in plans) to the Superpowers fork.

**Architecture:** One new skill plus reference files; extend three existing skills via progressive disclosure (thin SKILL.md deltas, heavy content in `references/`). Application repos receive copied templates — standards stay in fork `docs/standards/`. DDD is opt-in via `architecture mode: ddd` in stack files.

**Tech Stack:** Markdown skills (agentskills.io frontmatter), Cursor `.mdc` rules, shell for validation tests. No new runtime dependencies.

**Skill authoring:** Tasks that create or modify skills MUST follow `superpowers:writing-skills` and create-skill conventions (third-person `Use when…` descriptions, SKILL.md &lt;500 lines, references one level deep).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-06-29-project-standards-integration-design.md`
- One new skill only: `using-project-standards`
- Extend: `brainstorming`, `writing-plans`, `verification-before-completion` — do not replace their core flow
- DDD reference docs are optional packs; default `architecture mode: none`
- Do not paste full 771-line guidelines into rules or SKILL.md bodies
- Fork-only customization; do not assume upstream Superpowers PR
- Phase 8 (profile-scaled fitness tests) is **out of scope** for this plan

---

## File map (created or modified)

| Path | Responsibility |
|------|----------------|
| `templates/project/docs/TECH_STACK.md` | Org stack template copied to app repos |
| `templates/project/docs/PROJECT_STACK.md` | Product + entity catalog template |
| `templates/project/.cursor/rules/generic/*.mdc` | Always-on concise norms |
| `templates/project/.cursor/rules/stacks/rails8/*.mdc` | Rails-specific rule templates |
| `skills/using-project-standards/SKILL.md` | Bootstrap gate skill |
| `skills/using-project-standards/references/*.md` | Templates, stack detection |
| `skills/brainstorming/references/entity-impact.md` | Entity impact section template |
| `skills/brainstorming/SKILL.md` | +checklist items pointing to reference |
| `skills/writing-plans/references/stack-placement.md` | Stack file placement hints |
| `skills/writing-plans/references/ddd-applicability-template.md` | DDD plan section template |
| `skills/writing-plans/SKILL.md` | +conditional stack/DDD instructions |
| `skills/verification-before-completion/references/stack-verify.md` | Read TECH_STACK verify command |
| `skills/verification-before-completion/SKILL.md` | +pointer to stack-verify |
| `docs/standards/stacks/rails8/technical-guideline.md` | Canonical Rails8 reference |
| `docs/standards/stacks/rails8/ddd/*.md` | Optional DDD references |
| `tests/project-standards/test-skill-structure.sh` | Frontmatter + file presence checks |

---

### Task 1: Project templates and generic Cursor rules

**Files:**
- Create: `templates/project/docs/TECH_STACK.md`
- Create: `templates/project/docs/PROJECT_STACK.md`
- Create: `templates/project/.cursor/rules/generic/project-non-negotiables.mdc`
- Create: `templates/project/.cursor/rules/generic/project-testing.mdc`

**Interfaces:**
- Produces: template files consumed by `using-project-standards` copy steps in Task 2

- [ ] **Step 1: Create TECH_STACK.md template**

Create `templates/project/docs/TECH_STACK.md`:

```markdown
# Tech Stack

## Stack
generic

## Architecture mode
none

## DDD reference
<!-- only when architecture mode: ddd — e.g. docs/standards/stacks/rails8/ddd/ -->

## Verify command
<!-- stack-specific — e.g. bin/ci for rails8, npm test for node-api -->

## Norms & safeguards (summary)
See `.cursor/rules/` and `docs/standards/stacks/<stack>/`
```

- [ ] **Step 2: Create PROJECT_STACK.md template**

Create `templates/project/docs/PROJECT_STACK.md`:

```markdown
# Project Stack

## Product summary

## Core user loop

## Roles

## Architecture mode
none

## Entity catalog

| Entity | Module/Context | Description |
|--------|----------------|-------------|
| | | |

## Bounded contexts
<!-- only when architecture mode: ddd -->

| Context | Subdomain | Owner | Profile | Overrides | ADR |
|---------|-----------|-------|---------|-----------|-----|

## Context map
<!-- only when architecture mode: ddd -->

## Enabled add-ons

## Out of scope

## Open TBCs / assumptions
```

- [ ] **Step 3: Create generic non-negotiables rule**

Create `templates/project/.cursor/rules/generic/project-non-negotiables.mdc`:

```markdown
---
description: Core project norms — read stack files before coding
alwaysApply: true
---

# Project non-negotiables

Read `docs/PROJECT_STACK.md` for product and entity context.
Read `docs/TECH_STACK.md` for stack and architecture mode.
For full engineering detail: `docs/standards/stacks/<stack>/`

- No secrets in source; use env or credentials store.
- Authorization and validation at boundaries — never rely on UI hiding alone.
- Fix design spec and plan before code when behavior intent changes.
```

- [ ] **Step 4: Create generic testing rule**

Create `templates/project/.cursor/rules/generic/project-testing.mdc`:

```markdown
---
description: Testing baseline for this project
globs: "**/*{spec,test}*"
alwaysApply: false
---

# Testing

Read `docs/TECH_STACK.md` for the verify command.
Tests must cover behavior changed in the current task.
Do not claim done without running the verify command from TECH_STACK.
```

- [ ] **Step 5: Verify templates exist**

Run:
```bash
test -f templates/project/docs/TECH_STACK.md && \
test -f templates/project/docs/PROJECT_STACK.md && \
test -f templates/project/.cursor/rules/generic/project-non-negotiables.mdc && \
echo "PASS: Task 1 templates"
```
Expected: `PASS: Task 1 templates`

---

### Task 2: `using-project-standards` skill (create-skill / writing-skills)

**Files:**
- Create: `skills/using-project-standards/SKILL.md`
- Create: `skills/using-project-standards/references/tech-stack-template.md`
- Create: `skills/using-project-standards/references/project-stack-template.md`
- Create: `skills/using-project-standards/references/stack-detection.md`

**Interfaces:**
- Consumes: `templates/project/` from Task 1, `docs/standards/stacks/<stack>/` from Tasks 5–6
- Produces: skill invoked before `brainstorming` when stack files missing

**Authoring rules (create-skill):**
- `description` third person, starts with `Use when…`, no workflow summary in description
- SKILL.md body &lt;500 lines; templates in `references/`
- Announce line required at skill start

- [ ] **Step 1: Create reference — stack-detection.md**

Create `skills/using-project-standards/references/stack-detection.md`:

```markdown
# Stack detection

| Signal | Default `stack` | Default verify command |
|--------|-----------------|------------------------|
| `Gemfile` contains `gem "rails"` | `rails8` | `bin/ci` |
| `package.json` dependencies include `express` or `fastify` | `node-api` | `npm test` |
| Neither | `generic` | (human fills in TECH_STACK) |

Read repo root only. Do not guess beyond this table.
```

- [ ] **Step 2: Copy templates into references**

```bash
cp templates/project/docs/TECH_STACK.md skills/using-project-standards/references/tech-stack-template.md
cp templates/project/docs/PROJECT_STACK.md skills/using-project-standards/references/project-stack-template.md
```

- [ ] **Step 3: Write SKILL.md**

Create `skills/using-project-standards/SKILL.md`:

```markdown
---
name: using-project-standards
description: Use when starting work in a project, scaffolding a new MVP, or when docs/TECH_STACK.md or docs/PROJECT_STACK.md is missing — before brainstorming or writing code.
---

# Using Project Standards

## Overview

Bootstrap `TECH_STACK.md`, `PROJECT_STACK.md`, Cursor rules, and stack reference docs. Hard gate before feature work.

**Announce at start:** "I'm using the using-project-standards skill to verify this project is ready."

<HARD-GATE>
Do NOT invoke brainstorming, writing-plans, or test-driven-development until this skill completes and the human approves PROJECT_STACK.md.
</HARD-GATE>

## Checklist

Create a todo per item:

1. **Detect stack** — [stack-detection.md](references/stack-detection.md)
2. **TECH_STACK** — if missing, copy [tech-stack-template.md](references/tech-stack-template.md) to `docs/TECH_STACK.md`; set stack and verify command
3. **PROJECT_STACK** — if missing, copy [project-stack-template.md](references/project-stack-template.md) to `docs/PROJECT_STACK.md`
4. **Rules** — copy `templates/project/.cursor/rules/generic/` to `.cursor/rules/`; if stack is `rails8`, also copy `templates/project/.cursor/rules/stacks/rails8/`
5. **Standards** — if stack pack exists in fork at `docs/standards/stacks/<stack>/`, copy to app `docs/standards/stacks/<stack>/` (technical guideline only unless architecture mode is `ddd`)
6. **DDD pack** — only when `architecture mode: ddd` in TECH_STACK, copy `ddd/` subfolder
7. **Interactive fill** — product summary, seed entity catalog (2–5 rows), architecture mode; if `ddd`, bounded contexts table
8. **Human approval** — present `PROJECT_STACK.md`; hard stop until approved
9. **Hand off** — brainstorming for first feature, or wait

## When NOT to use

- Both `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` exist and are current
- Pure questions with no implementation intent

## Common mistakes

- Skipping human approval on PROJECT_STACK
- Copying DDD references when architecture mode is `none`
- Invoking brainstorming before bootstrap completes
```

- [ ] **Step 4: Verify skill structure**

Run:
```bash
grep -q '^name: using-project-standards' skills/using-project-standards/SKILL.md && \
grep -q '^description: Use when' skills/using-project-standards/SKILL.md && \
wc -l < skills/using-project-standards/SKILL.md | awk '{ if ($1 < 500) print "PASS: line count"; else print "FAIL: too long" }'
```
Expected: `PASS: line count`

- [ ] **Step 5: Pressure scenario note (writing-skills)**

Document in commit message or PR notes: agent without this skill will skip PROJECT_STACK and code immediately — skill must block via HARD-GATE language.

---

### Task 3: Extend `brainstorming` — entity impact (create-skill pattern)

**Files:**
- Create: `skills/brainstorming/references/entity-impact.md`
- Modify: `skills/brainstorming/SKILL.md` (checklist after item 1)

**Interfaces:**
- Consumes: `docs/TECH_STACK.md`, `docs/PROJECT_STACK.md` when present
- Produces: design specs with `## Entity impact` section

- [ ] **Step 1: Create entity-impact reference**

Create `skills/brainstorming/references/entity-impact.md`:

```markdown
# Entity impact (required in every design spec)

When `docs/PROJECT_STACK.md` exists, read it before design approval.

## Checklist

1. Map requirement keywords to entity catalog rows
2. Scan codebase for matches (models, domain types, API resources — per stack)
3. Add section to design spec:

## Entity impact

| Entity | Module/Context | Impact | Operations |
|--------|----------------|--------|------------|
| Order | orders | primary | create, update |

## Relationships touched
- Order → User

## Adjacent (not modified)
- Invoice (out of scope)

## Risks
- Cross-module writes

4. If architecture mode is `ddd`, add **Contexts involved** listing bounded contexts touched
5. New entities → update `docs/PROJECT_STACK.md` catalog before implementation
```

- [ ] **Step 2: Patch brainstorming checklist**

In `skills/brainstorming/SKILL.md`, after checklist item 1 (`Explore project context`), insert:

```markdown
1b. **Project stack context** — if `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` exist, read them; if missing and implementation intent, invoke `using-project-standards` first. Before design approval, complete [entity impact](references/entity-impact.md).
```

Renumber subsequent checklist items (2→2, etc.) or insert as `1b` without renumbering entire list — keep item 9 as `writing-plans` transition.

- [ ] **Step 3: Verify reference link resolves**

Run:
```bash
test -f skills/brainstorming/references/entity-impact.md && \
grep -q 'entity-impact.md' skills/brainstorming/SKILL.md && \
echo "PASS: brainstorming entity impact"
```
Expected: `PASS: brainstorming entity impact`

---

### Task 4: Extend `writing-plans` — stack placement and DDD applicability

**Files:**
- Create: `skills/writing-plans/references/stack-placement.md`
- Create: `skills/writing-plans/references/ddd-applicability-template.md`
- Modify: `skills/writing-plans/SKILL.md` (after Scope Check section)

**Interfaces:**
- Consumes: approved design spec, `TECH_STACK.md`, `PROJECT_STACK.md`
- Produces: plans with optional `## DDD applicability` and per-task entity/context tags

- [ ] **Step 1: Create stack-placement.md**

Create `skills/writing-plans/references/stack-placement.md`:

```markdown
# Stack placement in plans

Read `docs/TECH_STACK.md` for stack value and `docs/PROJECT_STACK.md` for entities.

## Every plan includes

```markdown
## Stack placement

**Stack:** <from TECH_STACK>
**Reference:** docs/standards/stacks/<stack>/
```

## rails8 (architecture mode: none)

- Controllers thin → services → models per technical-guideline §3
- Each task tags: **Module**, **Entities**, **Files**

## architecture mode: ddd

Also read [ddd-applicability-template.md](ddd-applicability-template.md) and add that section before tasks.
```

- [ ] **Step 2: Create ddd-applicability-template.md**

Create `skills/writing-plans/references/ddd-applicability-template.md` (content from spec lines 279–303 — contexts table, placement rules, boundaries, out of scope; link to `docs/standards/stacks/<stack>/ddd/`; target 30–80 lines).

- [ ] **Step 3: Patch writing-plans SKILL.md**

After `## Scope Check` in `skills/writing-plans/SKILL.md`, add:

```markdown
## Project standards

If `docs/TECH_STACK.md` exists in the target repo, read it and `docs/PROJECT_STACK.md` before writing tasks. Follow [stack-placement.md](references/stack-placement.md). When `architecture mode: ddd`, insert [DDD applicability](references/ddd-applicability-template.md) before tasks; each task tags Context, Profile, Entities when DDD is on.
```

- [ ] **Step 4: Verify**

```bash
test -f skills/writing-plans/references/stack-placement.md && \
test -f skills/writing-plans/references/ddd-applicability-template.md && \
grep -q 'stack-placement.md' skills/writing-plans/SKILL.md && \
echo "PASS: writing-plans extensions"
```
Expected: `PASS: writing-plans extensions`

---

### Task 5: Rails8 stack pack — standards + rule templates

**Files:**
- Create: `docs/standards/stacks/rails8/technical-guideline.md` (copy from repo root)
- Create: `templates/project/.cursor/rules/stacks/rails8/rails-controllers.mdc`
- Create: `templates/project/.cursor/rules/stacks/rails8/rails-models.mdc`
- Create: `templates/project/.cursor/rules/stacks/rails8/rails-services.mdc`

**Interfaces:**
- Consumes: `Rails8_Technical_Guideline 1.md` at repo root (untracked source)
- Produces: canonical fork copy + concise rails rules (~40 lines each)

- [ ] **Step 1: Copy technical guideline to standards path**

```bash
mkdir -p docs/standards/stacks/rails8
cp "Rails8_Technical_Guideline 1.md" docs/standards/stacks/rails8/technical-guideline.md
```

- [ ] **Step 2: Create rails-controllers.mdc**

Create `templates/project/.cursor/rules/stacks/rails8/rails-controllers.mdc`:

```markdown
---
description: Rails controller conventions
globs: app/controllers/**
alwaysApply: false
---

# Rails controllers

Read `docs/standards/stacks/rails8/technical-guideline.md` §3 for full detail.

- Thin: `params.expect`, `authorize`, delegate to service, render/redirect
- No business logic, no provider SDK calls
- No `permit!` / unfiltered mass assignment
```

- [ ] **Step 3: Create rails-models.mdc and rails-services.mdc**

`rails-models.mdc` — globs `app/models/**`: balanced AR, no orchestration, no `default_scope`, no provider calls.

`rails-services.mdc` — globs `app/services/**`: one use case per service, transaction boundary, context namespacing when DDD mode on.

- [ ] **Step 4: Verify**

```bash
test -f docs/standards/stacks/rails8/technical-guideline.md && \
ls templates/project/.cursor/rules/stacks/rails8/*.mdc | wc -l | grep -q 3 && \
echo "PASS: rails8 stack pack"
```
Expected: `PASS: rails8 stack pack`

---

### Task 6: Rails8 DDD reference pack (opt-in docs only)

**Files:**
- Create: `docs/standards/stacks/rails8/ddd/adoption-profiles.md`
- Create: `docs/standards/stacks/rails8/ddd/ddd-first-reference.md`

**Interfaces:**
- Copied to app repos only when `architecture mode: ddd`

- [ ] **Step 1: Copy DDD docs**

```bash
mkdir -p docs/standards/stacks/rails8/ddd
cp Rails8_DDD_Adoption_Profiles.md docs/standards/stacks/rails8/ddd/adoption-profiles.md
cp Rails8_DDD_First_Standard.md docs/standards/stacks/rails8/ddd/ddd-first-reference.md
```

- [ ] **Step 2: Add README guard**

Create `docs/standards/stacks/rails8/ddd/README.md`:

```markdown
# Rails8 DDD references (opt-in)

Load only when `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` set `architecture mode: ddd`.
DDD is not the default standard for Rails projects.
```

- [ ] **Step 3: Verify**

```bash
test -f docs/standards/stacks/rails8/ddd/adoption-profiles.md && \
test -f docs/standards/stacks/rails8/ddd/ddd-first-reference.md && \
echo "PASS: rails8 ddd pack"
```
Expected: `PASS: rails8 ddd pack`

---

### Task 7: Extend `verification-before-completion` — stack verify

**Files:**
- Create: `skills/verification-before-completion/references/stack-verify.md`
- Modify: `skills/verification-before-completion/SKILL.md` (end of Overview)

- [ ] **Step 1: Create stack-verify.md**

```markdown
# Stack verify command

If `docs/TECH_STACK.md` exists in the project repo, read the **Verify command** field and run that command as the primary done gate.

| stack | Typical command |
|-------|-----------------|
| rails8 | `bin/ci` |
| node-api | `npm test` |
| generic | value from TECH_STACK |

Profile-scaled fitness tests are optional; default gates still apply.
```

- [ ] **Step 2: Patch SKILL.md**

Add after Overview in `skills/verification-before-completion/SKILL.md`:

```markdown
When verifying application repos with `docs/TECH_STACK.md`, follow [stack-verify.md](references/stack-verify.md) for the primary verify command.
```

- [ ] **Step 3: Verify**

```bash
grep -q 'stack-verify.md' skills/verification-before-completion/SKILL.md && \
echo "PASS: verification extension"
```
Expected: `PASS: verification extension`

---

### Task 8: Fork validation test script

**Files:**
- Create: `tests/project-standards/test-skill-structure.sh`

- [ ] **Step 1: Write test script**

Create `tests/project-standards/test-skill-structure.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $1"; exit 1; }

# New skill exists with valid frontmatter
grep -q '^name: using-project-standards' skills/using-project-standards/SKILL.md || fail "missing using-project-standards name"
grep -q '^description: Use when' skills/using-project-standards/SKILL.md || fail "bad description"

# References exist
test -f skills/brainstorming/references/entity-impact.md || fail "entity-impact"
test -f skills/writing-plans/references/stack-placement.md || fail "stack-placement"
test -f skills/writing-plans/references/ddd-applicability-template.md || fail "ddd template"
test -f skills/verification-before-completion/references/stack-verify.md || fail "stack-verify"

# Templates
test -f templates/project/docs/TECH_STACK.md || fail "TECH_STACK template"
test -f templates/project/docs/PROJECT_STACK.md || fail "PROJECT_STACK template"

# Rails8 pack
test -f docs/standards/stacks/rails8/technical-guideline.md || fail "rails8 guideline"
test -f docs/standards/stacks/rails8/ddd/adoption-profiles.md || fail "ddd adoption"

echo "PASS: project-standards structure"
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x tests/project-standards/test-skill-structure.sh
./tests/project-standards/test-skill-structure.sh
```
Expected: `PASS: project-standards structure`

- [ ] **Step 3: Run shell lint on new script**

```bash
./scripts/lint-shell.sh tests/project-standards/test-skill-structure.sh
```
Expected: exit 0

---

### Task 9: Integration smoke checklist (manual)

**Files:** none (verification only)

- [ ] **Step 1: Simulated greenfield Rails repo**

In a temp directory:
```bash
mkdir -p /tmp/ps-smoke && cd /tmp/ps-smoke
echo 'gem "rails"' > Gemfile
```
Confirm `using-project-standards` references point at `templates/project/` paths that exist in fork (read SKILL.md checklist).

- [ ] **Step 2: Confirm skill chain documented**

Verify design spec success criteria map to Tasks 1–8:
- Bootstrap skill ✓ Task 2
- Entity impact ✓ Task 3
- DDD applicability in plans ✓ Task 4
- Rails reference ✓ Task 5–6
- Stack verify ✓ Task 7

- [ ] **Step 3: Record smoke result**

Note pass/fail in PR description or handoff; no automated harness required for smoke in v1.

---

## Plan self-review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| TECH_STACK + PROJECT_STACK split | 1, 2 |
| using-project-standards hard gate | 2 |
| Entity impact in brainstorming | 3 |
| DDD applicability in plans (links not paste) | 4 |
| Rails8 technical guideline reference | 5 |
| DDD opt-in reference pack | 6 |
| Stack verify in verification skill | 7 |
| Automated structure test | 8 |
| Phase 8 fitness tests | Out of scope |

Placeholder scan: none.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-29-project-standards-integration.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
