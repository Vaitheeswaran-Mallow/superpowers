# DDD Architecture Modes & Package-First Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three architecture modes (`none`, `ddd-companion`, `ddd-first`), ship the Architecture & DDD companion standard, document package-first Rails layout under `app/domains/`, and wire bootstrap/skills/rules so agents place code in bounded-context packages.

**Architecture:** Extend the existing project-standards fork (one skill + reference packs). Standards stay in `docs/standards/`; bootstrap copies mode-specific subsets. Package layout is canonical in `rails-package-layout.md`; enforcement via always-on DDD Cursor rules and plan templates with mandatory file paths. Zeitwerk collapse initializer ships as a project template.

**Tech Stack:** Markdown skills, Cursor `.mdc` rules, bash structure tests. No new runtime dependencies.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-06-30-ddd-architecture-modes-design.md`
- Builds on: `docs/superpowers/plans/2026-06-29-project-standards-integration.md` (already landed or in progress)
- Architecture modes: `none` | `ddd-companion` | `ddd-first` (legacy `ddd` → `ddd-companion`)
- Package root: `app/domains/<context>/{domain,application,infrastructure,interface}/`
- Interface inside package — not `app/controllers/<context>/`
- Ruby modules flat per context: `Billing::Invoice` via Zeitwerk collapse
- `ddd-first` copies only `ddd-first-reference.md` + `rails-package-layout.md` — no `technical-guideline.md`
- Do not paste full standard prose into SKILL.md or rules (pointers + concise tables only)
- Packwerk, CI fitness tests, upstream PR — out of scope
- Fork-only customization

## DDD applicability (this plan)

**Reference docs:**
- `docs/superpowers/specs/2026-06-30-ddd-architecture-modes-design.md`
- `docs/standards/stacks/rails8/ddd/rails-package-layout.md` (created Task 1)

**Contexts touched:** N/A (fork infrastructure — no app bounded contexts)

**Placement rules:** All new Rails examples use `app/domains/<context>/…` paths.

**Boundaries:** Do not modify `technical-guideline.md` body or full DDD standard prose except adoption-profiles path references.

---

## File map

| Path | Responsibility |
|------|----------------|
| `docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md` | Companion standard (copy from repo root) |
| `docs/standards/stacks/rails8/ddd/rails-package-layout.md` | Canonical package-first layout + Zeitwerk |
| `docs/standards/stacks/rails8/ddd/README.md` | Mode → file manifest |
| `docs/standards/stacks/rails8/ddd/adoption-profiles.md` | Package paths + in-repo substrate link |
| `templates/project/config/initializers/zeitwerk.rb` | Collapse dirs for `app/domains` |
| `templates/project/docs/contexts/_template.md` | Glossary stub for bootstrap |
| `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-*.mdc` | DDD enforcement rules |
| `skills/using-project-standards/references/ddd-bootstrap-scaffold.md` | mkdir/cp steps for package scaffold |
| `skills/using-project-standards/references/mode-standards-copy.md` | Which files copy per mode |
| `tests/project-standards/test-skill-structure.sh` | Assert new artifacts |
| `tests/project-standards/test-ddd-package-layout.sh` | Content checks on layout doc |

---

### Task 1: DDD standards pack — companion standard, package layout, README

**Files:**
- Create: `docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md`
- Create: `docs/standards/stacks/rails8/ddd/rails-package-layout.md`
- Modify: `docs/standards/stacks/rails8/ddd/README.md`
- Modify: `docs/standards/stacks/rails8/ddd/adoption-profiles.md`

**Interfaces:**
- Produces: `rails-package-layout.md` referenced by rules, skills, and tests
- Produces: `architecture-and-ddd-standard.md` linked from adoption-profiles

- [ ] **Step 1: Copy Architecture & DDD Standard into the pack**

```bash
cp Architecture_and_DDD_Standard.md docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md
```

- [ ] **Step 2: Create rails-package-layout.md**

Create `docs/standards/stacks/rails8/ddd/rails-package-layout.md`:

```markdown
# Rails 8 — Package-First Bounded Context Layout

Canonical on-disk layout when `architecture mode` is `ddd-companion` or `ddd-first`.
Read with `docs/PROJECT_STACK.md` bounded contexts.

## Terminology

| Path segment | Meaning |
|--------------|---------|
| `app/domains/<context>/` | Bounded-context **package** (not the domain layer) |
| `…/domain/` | Domain layer (aggregates, value objects) |
| `…/application/` | Application layer (use cases, sagas, context jobs) |
| `…/infrastructure/` | Adapters, repositories (L2), read models (L3) |
| `…/interface/` | Controllers, presenters, channels |

Ruby constants are **flat per context**: `Billing::Invoice`, not `Billing::Domain::Invoice`.
Requires Zeitwerk collapse — see `config/initializers/zeitwerk.rb`.

## Per-context tree

```
app/domains/billing/
├── domain/
│   └── invoice.rb                 # Billing::Invoice
├── application/
│   └── record_usage.rb            # Billing::RecordUsage
├── infrastructure/
│   └── adapters/stripe_adapter.rb # Billing::StripeAdapter
└── interface/
    └── invoices_controller.rb     # Billing::InvoicesController

docs/contexts/billing.md
```

## Construct → path

| Construct | Path |
|-----------|------|
| Controller / presenter | `app/domains/<context>/interface/` |
| Application service / saga | `app/domains/<context>/application/` |
| Aggregate / VO | `app/domains/<context>/domain/` |
| Adapter (ACL) | `app/domains/<context>/infrastructure/adapters/` |
| Repository (L2) | `app/domains/<context>/infrastructure/repositories/` |
| Read model (L3) | `app/domains/<context>/infrastructure/read_models/` |
| Context-owned job | `app/domains/<context>/application/` |

## Shared (non-context)

- `app/models/application_record.rb`
- `app/models/outbox_event.rb`
- `app/jobs/outbox_relay_job.rb`

## Hard rules

- No flat `app/models/<entity>.rb` for context-owned entities when package applies.
- No provider SDK outside `infrastructure/adapters/`.
- Routes: `namespace :billing` matching context name.
- Cross-context: published interface / ACL / events only.

## Mode differences

| Mode | Package required |
|------|------------------|
| `ddd-first` | Every bounded context — all four layer subfolders |
| `ddd-companion` | Pragmatic / Full DDD profiles only; Omakase may use conventional paths |

## Zeitwerk collapse

Ship `config/initializers/zeitwerk.rb` from project templates. Collapses layer folders so
`app/domains/billing/domain/invoice.rb` → `Billing::Invoice`.
```

- [ ] **Step 3: Update ddd/README.md**

Replace `docs/standards/stacks/rails8/ddd/README.md` with:

```markdown
# Rails8 DDD references (opt-in)

Load based on `docs/TECH_STACK.md` **Architecture mode**. DDD is not the default.

| Mode | Files copied to app repo |
|------|--------------------------|
| `none` | (no files from this folder) |
| `ddd-companion` | `architecture-and-ddd-standard.md`, `adoption-profiles.md`, `rails-package-layout.md` + parent `technical-guideline.md` |
| `ddd-first` | `ddd-first-reference.md`, `rails-package-layout.md` only |

Legacy `architecture mode: ddd` is treated as `ddd-companion`.

Also in fork (not always copied): `ddd-first-reference.md` (full DDD-first standard).
```

- [ ] **Step 4: Update adoption-profiles.md substrate link**

In `docs/standards/stacks/rails8/ddd/adoption-profiles.md`, replace the substrate sentence (line ~5) with:

```markdown
**Relationship to the substrate.** Profiles are **presets over the layer model** (L0–L4) defined in **`architecture-and-ddd-standard.md`** (in this folder), with cross-cutting rules from the **Rails 8 Technical Guideline v1.4**. On-disk layout: **`rails-package-layout.md`** in this folder.
```

In the Pragmatic DDD **Structure** bullet (~line 36), append:

```markdown
Package layout per `rails-package-layout.md` (`app/domains/<context>/…`).
```

- [ ] **Step 5: Verify files exist**

```bash
test -f docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md
test -f docs/standards/stacks/rails8/ddd/rails-package-layout.md
grep -q 'ddd-companion' docs/standards/stacks/rails8/ddd/README.md
grep -q 'rails-package-layout' docs/standards/stacks/rails8/ddd/adoption-profiles.md
echo "Task 1 OK"
```

- [ ] **Step 6: Commit**

```bash
git add docs/standards/stacks/rails8/ddd/
git commit -m "Add DDD companion standard and package-first layout doc."
```

---

### Task 2: Bootstrap templates — Zeitwerk, context glossary, stack files

**Files:**
- Create: `templates/project/config/initializers/zeitwerk.rb`
- Create: `templates/project/docs/contexts/_template.md`
- Modify: `templates/project/docs/TECH_STACK.md`
- Modify: `templates/project/docs/PROJECT_STACK.md`
- Modify: `skills/using-project-standards/references/tech-stack-template.md`
- Modify: `skills/using-project-standards/references/project-stack-template.md`

**Interfaces:**
- Produces: templates consumed by `using-project-standards` (Task 4)
- Produces: `zeitwerk.rb` content referenced in `rails-package-layout.md`

- [ ] **Step 1: Create Zeitwerk initializer template**

Create `templates/project/config/initializers/zeitwerk.rb`:

```ruby
# frozen_string_literal: true

# Collapse app/domains/<context>/{domain,application,infrastructure,interface}
# so Billing::Invoice lives at app/domains/billing/domain/invoice.rb
# See docs/standards/stacks/rails8/ddd/rails-package-layout.md

Rails.application.config.to_prepare do
  loader = Rails.autoloaders.main

  %w[domain application infrastructure interface].each do |layer|
    Dir[Rails.root.join("app/domains/*/#{layer}")].each do |path|
      loader.collapse(path)
    end
  end

  %w[adapters repositories read_models].each do |sub|
    Dir[Rails.root.join("app/domains/*/infrastructure/#{sub}")].each do |path|
      loader.collapse(path)
    end
  end
end
```

- [ ] **Step 2: Create context glossary template**

Create `templates/project/docs/contexts/_template.md`:

```markdown
# <Context name> — Ubiquitous language

## Overview

## Terms

| Term | Definition |
|------|------------|
| | |

## Aggregates

| Aggregate | Invariants (summary) |
|-----------|---------------------|
| | |

## Published events / interfaces

## Relationships to other contexts
```

- [ ] **Step 3: Update TECH_STACK templates**

Replace `## Architecture mode` section in both `templates/project/docs/TECH_STACK.md` and `skills/using-project-standards/references/tech-stack-template.md`:

```markdown
## Architecture mode
none                    # or: ddd-companion, ddd-first

## Standards reference
<!-- none: docs/standards/stacks/rails8/technical-guideline.md -->
<!-- ddd-companion: technical-guideline.md + docs/standards/stacks/rails8/ddd/ (companion + profiles + layout) -->
<!-- ddd-first: docs/standards/stacks/rails8/ddd/ddd-first-reference.md + rails-package-layout.md -->
```

Remove the old `## DDD reference` block (folded into Standards reference).

- [ ] **Step 4: Update PROJECT_STACK templates**

In both `templates/project/docs/PROJECT_STACK.md` and `skills/using-project-standards/references/project-stack-template.md`:

Replace bounded-contexts comment and table header with:

```markdown
## Bounded contexts
<!-- when architecture mode: ddd-companion or ddd-first -->

| Context | Subdomain | Owner | Profile or Depth | Overrides | ADR |
|---------|-----------|-------|------------------|-----------|-----|

<!-- ddd-companion: Profile = Omakase | Pragmatic | Full DDD -->
<!-- ddd-first: Profile or Depth = thin | moderate | deep -->
```

- [ ] **Step 5: Verify**

```bash
test -f templates/project/config/initializers/zeitwerk.rb
test -f templates/project/docs/contexts/_template.md
grep -q 'ddd-companion' templates/project/docs/TECH_STACK.md
grep -q 'Profile or Depth' templates/project/docs/PROJECT_STACK.md
echo "Task 2 OK"
```

- [ ] **Step 6: Commit**

```bash
git add templates/project/ skills/using-project-standards/references/
git commit -m "Add DDD bootstrap templates for three architecture modes."
```

---

### Task 3: DDD Cursor rules

**Files:**
- Create: `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-structure.mdc`
- Create: `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-companion.mdc`
- Create: `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-first.mdc`
- Modify: `templates/project/.cursor/rules/stacks/rails8/rails-models.mdc`
- Modify: `templates/project/.cursor/rules/stacks/rails8/rails-services.mdc`
- Modify: `templates/project/.cursor/rules/stacks/rails8/rails-controllers.mdc`

**Interfaces:**
- Produces: rules copied selectively per mode in Task 4

- [ ] **Step 1: Create rails8-ddd-structure.mdc**

```markdown
---
description: DDD package-first layout for bounded contexts
globs: app/domains/**
alwaysApply: false
---

# DDD package structure

Read `docs/TECH_STACK.md` architecture mode and `docs/standards/stacks/rails8/ddd/rails-package-layout.md`.

## Layout (mandatory when DDD mode on)

```
app/domains/<context>/
  domain/           # aggregates, value objects → Billing::Invoice
  application/      # use cases, sagas, jobs → Billing::RecordUsage
  infrastructure/   # adapters/, repositories/, read_models/
  interface/        # controllers, presenters → Billing::InvoicesController
```

- Context name = lowercase folder + Ruby module (`billing` → `Billing::`)
- No flat `app/models/<entity>.rb` for context-owned entities
- No provider SDK outside `infrastructure/adapters/`
- Interface delegates to application → domain only

## Docs

- Glossary per context: `docs/contexts/<context>.md`
- Bounded contexts table: `docs/PROJECT_STACK.md`
```

- [ ] **Step 2: Create rails8-ddd-companion.mdc**

```markdown
---
description: DDD companion mode — guideline + adoption profiles
alwaysApply: true
---

# Architecture mode: ddd-companion

Read `docs/standards/stacks/rails8/technical-guideline.md` for cross-cutting rules.
Read `docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md` for domain layers.
Read `docs/standards/stacks/rails8/ddd/adoption-profiles.md` for per-context profile.

Package layout: `rails-package-layout.md`. Omakase-profile contexts may use conventional Rails paths; Pragmatic/Full use `app/domains/<context>/`.
```

- [ ] **Step 3: Create rails8-ddd-first.mdc**

```markdown
---
description: DDD-first mode — four-layer spine, all contexts packaged
alwaysApply: true
---

# Architecture mode: ddd-first

Read `docs/standards/stacks/rails8/ddd/ddd-first-reference.md` (primary standard).
Read `docs/standards/stacks/rails8/ddd/rails-package-layout.md` for paths.

Every bounded context uses full package: domain/, application/, infrastructure/, interface/.
No omakase flat models for context-owned entities. Tactical depth varies; folder layout does not.
```

- [ ] **Step 4: Add superseded note to omakase rails rules**

Append to each of `rails-models.mdc`, `rails-services.mdc`, `rails-controllers.mdc` after the frontmatter block:

```markdown
When `docs/TECH_STACK.md` architecture mode is `ddd-companion` or `ddd-first`, path placement follows `rails8-ddd-structure.mdc` and mode-specific DDD rules.
```

- [ ] **Step 5: Verify**

```bash
ls templates/project/.cursor/rules/stacks/rails8/rails8-ddd-*.mdc | wc -l | grep -q 3
grep -q 'rails-package-layout' templates/project/.cursor/rules/stacks/rails8/rails8-ddd-structure.mdc
echo "Task 3 OK"
```

- [ ] **Step 6: Commit**

```bash
git add templates/project/.cursor/rules/stacks/rails8/
git commit -m "Add DDD Cursor rules for package-first layout."
```

---

### Task 4: using-project-standards — three modes, copy matrix, scaffold

**Files:**
- Create: `skills/using-project-standards/references/mode-standards-copy.md`
- Create: `skills/using-project-standards/references/ddd-bootstrap-scaffold.md`
- Modify: `skills/using-project-standards/SKILL.md`

**Interfaces:**
- Produces: checklist steps 4–7 behavior for implementers and agents

- [ ] **Step 1: Create mode-standards-copy.md**

Create `skills/using-project-standards/references/mode-standards-copy.md`:

```markdown
# Standards and rules copy matrix

Read `docs/TECH_STACK.md` **Architecture mode**. Normalize legacy `ddd` → `ddd-companion`.

## Standards (into app `docs/standards/stacks/rails8/`)

| Mode | Copy |
|------|------|
| `none` | `technical-guideline.md` only |
| `ddd-companion` | `technical-guideline.md` + entire `ddd/` folder from fork |
| `ddd-first` | `ddd/ddd-first-reference.md` + `ddd/rails-package-layout.md` only |

## Cursor rules (into app `.cursor/rules/`)

Always: `generic/*`

| Mode | Also copy from `stacks/rails8/` |
|------|--------------------------------|
| `none` | `rails-controllers.mdc`, `rails-models.mdc`, `rails-services.mdc` |
| `ddd-companion` | omakase rails rules + `rails8-ddd-structure.mdc` + `rails8-ddd-companion.mdc` |
| `ddd-first` | `rails8-ddd-structure.mdc` + `rails8-ddd-first.mdc` only |
```

- [ ] **Step 2: Create ddd-bootstrap-scaffold.md**

Create `skills/using-project-standards/references/ddd-bootstrap-scaffold.md`:

```markdown
# DDD package scaffold (after bounded contexts filled)

Run when architecture mode is `ddd-companion` or `ddd-first` and `PROJECT_STACK.md` has context rows.

## Which contexts get a package

| Mode | Scaffold when |
|------|----------------|
| `ddd-first` | Every context row |
| `ddd-companion` | Profile is Pragmatic or Full DDD (not Omakase) |

## Commands (CONTEXT = lowercase context name, e.g. billing)

```bash
mkdir -p "app/domains/${CONTEXT}/domain"
mkdir -p "app/domains/${CONTEXT}/application"
mkdir -p "app/domains/${CONTEXT}/infrastructure/adapters"
mkdir -p "app/domains/${CONTEXT}/interface"
touch "app/domains/${CONTEXT}/domain/.keep"
touch "app/domains/${CONTEXT}/application/.keep"
touch "app/domains/${CONTEXT}/infrastructure/adapters/.keep"
touch "app/domains/${CONTEXT}/interface/.keep"
mkdir -p docs/contexts
cp templates/project/docs/contexts/_template.md "docs/contexts/${CONTEXT}.md"  # from fork paths when in app repo, use fork template at bootstrap
```

## Zeitwerk

If `config/initializers/zeitwerk.rb` missing, copy from `templates/project/config/initializers/zeitwerk.rb`.

## Glossary

Edit each `docs/contexts/<context>.md` — replace placeholder title with context name.
```

- [ ] **Step 3: Update using-project-standards SKILL.md checklist**

Replace steps 4–7 in `skills/using-project-standards/SKILL.md`:

```markdown
4. **Rules** — copy `generic/`; then per [mode-standards-copy.md](references/mode-standards-copy.md) copy rails8 rules for the architecture mode
5. **Standards** — per [mode-standards-copy.md](references/mode-standards-copy.md); normalize legacy `architecture mode: ddd` to `ddd-companion`
6. **DDD scaffold** — when mode is `ddd-companion` or `ddd-first`, follow [ddd-bootstrap-scaffold.md](references/ddd-bootstrap-scaffold.md) for each qualifying bounded context
7. **Interactive fill** — product summary, entity catalog (2–5 rows), architecture mode; bounded contexts table when DDD mode on
8. **Human approval** — present `PROJECT_STACK.md`; hard stop until approved
9. **Hand off** — brainstorming for first feature, or wait
```

Update **Common mistakes**:

```markdown
- Copying full `ddd/` pack when mode is `ddd-first` (only two files)
- Scaffolding packages for Omakase-profile contexts in ddd-companion mode
- Skipping `config/initializers/zeitwerk.rb`
```

- [ ] **Step 4: Verify**

```bash
grep -q 'mode-standards-copy' skills/using-project-standards/SKILL.md
grep -q 'ddd-bootstrap-scaffold' skills/using-project-standards/SKILL.md
grep -q 'ddd-companion' skills/using-project-standards/references/mode-standards-copy.md
echo "Task 4 OK"
```

- [ ] **Step 5: Commit**

```bash
git add skills/using-project-standards/
git commit -m "Wire three architecture modes into using-project-standards."
```

---

### Task 5: writing-plans and brainstorming references

**Files:**
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/writing-plans/references/stack-placement.md`
- Modify: `skills/writing-plans/references/ddd-applicability-template.md`
- Modify: `skills/brainstorming/references/entity-impact.md`

- [ ] **Step 1: Update writing-plans SKILL.md project standards line**

Replace line 27:

```markdown
If `docs/TECH_STACK.md` exists in the target repo, read it and `docs/PROJECT_STACK.md` before writing tasks. Follow [stack-placement.md](references/stack-placement.md). When architecture mode is `ddd-companion` or `ddd-first`, insert [DDD applicability](references/ddd-applicability-template.md) before tasks; each task tags Context, Profile or Depth, Entities, and **Files** with package paths.
```

- [ ] **Step 2: Replace stack-placement.md**

```markdown
# Stack placement in plans

Read `docs/TECH_STACK.md` for stack and architecture mode; `docs/PROJECT_STACK.md` for entities.

## Every plan includes

```markdown
## Stack placement

**Stack:** <from TECH_STACK>
**Architecture mode:** <none | ddd-companion | ddd-first>
**Reference:** docs/standards/stacks/<stack>/ (+ ddd/ when DDD mode on)
**Layout:** docs/standards/stacks/rails8/ddd/rails-package-layout.md (when DDD on)
```

## rails8 — architecture mode: none

- Conventional Rails: thin controllers → services → models per technical-guideline §3
- Each task tags: **Module**, **Entities**, **Files**

## rails8 — architecture mode: ddd-companion

- Package layout for Pragmatic/Full contexts: `app/domains/<context>/…`
- Read adoption-profiles for profile per context
- Add [ddd-applicability-template.md](ddd-applicability-template.md) before tasks

## rails8 — architecture mode: ddd-first

- Every context uses full package; read ddd-first-reference.md
- Add ddd-applicability section; use **Depth** not Profile
```

- [ ] **Step 3: Replace ddd-applicability-template.md**

Use package paths in examples; add mode-specific doc links and mandatory Files:

```markdown
# DDD applicability (insert before tasks when architecture mode is ddd-companion or ddd-first)

```markdown
## DDD applicability (this feature)

**Architecture mode:** <ddd-companion | ddd-first>

**Reference docs** (read on demand):
- docs/standards/stacks/rails8/ddd/rails-package-layout.md
- ddd-companion: architecture-and-ddd-standard.md, adoption-profiles.md, technical-guideline.md
- ddd-first: ddd-first-reference.md

**Contexts touched**

| Context | Subdomain | Profile/Depth | Layers this feature |
|---------|-----------|---------------|---------------------|
| Billing | Core | Pragmatic | L1: aggregate, outbox |

**Placement (package-first)**

| Context | Application | Domain | Infrastructure | Interface |
|---------|-------------|--------|----------------|-----------|
| Billing | record_usage.rb | invoice.rb | adapters/stripe_adapter.rb | invoices_controller.rb |

Paths relative to `app/domains/billing/`.

**Boundaries**
- No cross-context table writes; ACL/events only

**Out of scope**
- L2, L4 (unless profile/depth requires)
```

## Per-task requirements

Each task MUST include **Files** with full paths, e.g.:
- `app/domains/billing/application/record_usage.rb` (Application)
- `app/domains/billing/domain/invoice.rb` (Domain)

Also tag: **Context**, **Profile or Depth**, **Entities**, **Pattern**
```

- [ ] **Step 4: Update entity-impact.md step 4**

Replace step 4 with:

```markdown
4. If architecture mode is `ddd-companion` or `ddd-first`, add **Contexts involved** and optional **Package paths** (`app/domains/<context>/…`) per rails-package-layout.md
```

- [ ] **Step 5: Verify**

```bash
grep -q 'ddd-first' skills/writing-plans/references/stack-placement.md
grep -q 'app/domains' skills/writing-plans/references/ddd-applicability-template.md
grep -q 'ddd-companion' skills/brainstorming/references/entity-impact.md
echo "Task 5 OK"
```

- [ ] **Step 6: Commit**

```bash
git add skills/writing-plans/ skills/brainstorming/references/entity-impact.md
git commit -m "Update plan and brainstorm references for package-first DDD."
```

---

### Task 6: Structure tests

**Files:**
- Modify: `tests/project-standards/test-skill-structure.sh`
- Create: `tests/project-standards/test-ddd-package-layout.sh`

- [ ] **Step 1: Extend test-skill-structure.sh**

Add before the final `echo "PASS"`:

```bash
test -f docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md || fail "architecture-and-ddd-standard"
test -f docs/standards/stacks/rails8/ddd/rails-package-layout.md || fail "rails-package-layout"
test -f templates/project/config/initializers/zeitwerk.rb || fail "zeitwerk template"
test -f templates/project/docs/contexts/_template.md || fail "context template"
test -f skills/using-project-standards/references/mode-standards-copy.md || fail "mode-standards-copy"
test -f skills/using-project-standards/references/ddd-bootstrap-scaffold.md || fail "ddd-bootstrap-scaffold"
ls templates/project/.cursor/rules/stacks/rails8/rails8-ddd-*.mdc 2>/dev/null | grep -q . || fail "ddd cursor rules"
grep -q 'ddd-companion' skills/using-project-standards/SKILL.md || fail "three modes in skill"
```

- [ ] **Step 2: Create test-ddd-package-layout.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $1"; exit 1; }

LAYOUT=docs/standards/stacks/rails8/ddd/rails-package-layout.md
test -f "$LAYOUT" || fail "missing layout doc"
grep -q 'app/domains/' "$LAYOUT" || fail "missing app/domains"
grep -q 'interface/' "$LAYOUT" || fail "missing interface layer"
grep -q 'Zeitwerk' "$LAYOUT" || fail "missing zeitwerk"
grep -q 'ddd-first' "$LAYOUT" || fail "missing mode table"

echo "PASS: ddd package layout"
```

- [ ] **Step 3: Run tests**

```bash
chmod +x tests/project-standards/test-ddd-package-layout.sh
./tests/project-standards/test-skill-structure.sh
./tests/project-standards/test-ddd-package-layout.sh
```

Expected: both print `PASS`

- [ ] **Step 4: Commit**

```bash
git add tests/project-standards/
git commit -m "Add structure tests for DDD architecture modes."
```

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| Three architecture modes | 2, 4 |
| architecture-and-ddd-standard in pack | 1 |
| rails-package-layout.md | 1 |
| Package-first app/domains layout | 1, 3 |
| Interface in package | 1, 3 |
| Zeitwerk collapse template | 2 |
| Bootstrap scaffold | 2, 4 |
| Mode-specific standards copy | 4 |
| DDD Cursor rules | 3 |
| writing-plans / entity-impact updates | 5 |
| Legacy `ddd` → `ddd-companion` | 4 |
| Structure tests | 6 |

## Follow-ups (not in this plan)

- Architecture-fitness RSpec in `bin/ci`
- Packwerk per `app/domains/<context>/`
- Agent eval: “add billing invoice” lands in package paths
