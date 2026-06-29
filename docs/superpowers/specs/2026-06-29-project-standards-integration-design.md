# Project Standards Integration — Generic MVP Workflow for Superpowers Fork

Integrate a generic, stack-aware project bootstrap and per-feature workflow into a customized Superpowers fork for Cursor. Rails 8 engineering standards and optional DDD references are load-on-demand packs — not the workflow spine. Entity impact per requirement is borrowed lightly from [Structured-Prompt-Driven Development (SPDD)](https://martinfowler.com/articles/structured-prompt-driven/) without adopting the full REASONS Canvas machinery.

## Problem

Teams building MVPs in Cursor with a Superpowers fork lack:

1. A consistent pre-dev gate (profile, product context, rules installed) before brainstorming or coding.
2. Clear separation between org-wide tooling norms and per-product decisions.
3. Explicit identification of which domain entities a requirement affects before implementation.
4. Stack-specific engineering references (Rails 8 Technical Guideline) without forcing DDD on every project.
5. A single skill chain that works for Rails and non-Rails repos.

Ad hoc chats and undifferentiated rules cause profile drift, missed boundaries, and agents that cannot tell *what this MVP chose* from *how we always build*.

## Goals

- One generic workflow in the Superpowers fork; stack behavior via reference packs named in `TECH_STACK.md`.
- Bootstrap new repos with `using-project-standards` before feature work.
- Split `TECH_STACK.md` (org/tooling) and `PROJECT_STACK.md` (product/entities).
- Entity impact table in every feature design spec (brainstorming output).
- Rails 8 Technical Guideline as reference under `docs/standards/stacks/rails8/` when `stack: rails8`.
- DDD docs optional under `docs/standards/stacks/<stack>/ddd/` when `architecture mode: ddd` — not the default standard.
- Plans include a **DDD applicability** section (links + feature-scoped tables) when DDD is enabled — not full standard text.
- Extend existing Superpowers skills (`brainstorming`, `writing-plans`, `verification-before-completion`); add only one new skill: `using-project-standards`.
- Zero external CLI dependencies (no openspdd); skills + versioned repo artifacts only.

## Non-goals

- Full SPDD implementation (REASONS Canvas, `writing-reasons-canvas`, `updating-reasons-canvas`, `syncing-reasons-canvas`).
- Agent-orchestrator / `agentctl` integration (Superpowers alone in Cursor).
- Mandating DDD on any project by default.
- Pasting full 771-line guidelines into Cursor rules or plans.
- Upstream Superpowers PR (fork-specific customization).

## Architecture

Four layers, one job each:

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| A | Superpowers fork skills + templates | Workflow gates and orchestration |
| B | `.cursor/rules/` in each repo | Always-on concise coding norms |
| C | `TECH_STACK.md` + `PROJECT_STACK.md` | Org tooling vs product truth |
| D | CI (`bin/ci`, `npm test`, etc.) | Hard enforcement agents cannot bypass |

Reference docs live under `docs/standards/` and are read on demand — never duplicated verbatim in rules or plans.

### Standards layering

```
Generic (every project)
  using-project-standards · TECH_STACK · PROJECT_STACK · entity catalog
  superpowers: brainstorming → writing-plans → TDD → verify

Optional stack pack (e.g. rails8)
  technical-guideline.md · stack-specific .cursor/rules templates

Optional DDD pack (per stack, when architecture mode: ddd)
  stacks/<stack>/ddd/adoption-profiles.md · ddd-first-reference.md
```

DDD is an **architecture mode**, not part of the default domain standard. Rails projects use the Technical Guideline for engineering; DDD references apply only when opted in via `PROJECT_STACK` and `TECH_STACK`.

## Repository layout (per application repo)

```
my-app/
├── docs/
│   ├── TECH_STACK.md
│   ├── PROJECT_STACK.md
│   ├── standards/
│   │   └── stacks/
│   │       ├── rails8/                    # copied when stack: rails8
│   │       │   ├── technical-guideline.md
│   │       │   └── ddd/                   # copied only when architecture mode: ddd
│   │       │       ├── adoption-profiles.md
│   │       │       └── ddd-first-reference.md
│   │       └── node-api/                  # future packs
│   └── superpowers/
│       ├── specs/                         # brainstorming design specs
│       └── plans/                         # writing-plans output
├── .cursor/rules/
└── (application code)
```

## Fork layout

```
superpowers/
├── skills/
│   ├── using-project-standards/           # NEW
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── tech-stack-template.md
│   │       ├── project-stack-template.md
│   │       └── stack-detection.md
│   ├── brainstorming/SKILL.md             # MODIFIED: entity impact checklist
│   ├── writing-plans/
│   │   ├── SKILL.md                       # MODIFIED: pointer to references
│   │   └── references/
│   │       ├── stack-placement.md
│   │       └── ddd-applicability-template.md
│   └── verification-before-completion/
│       └── references/
│           └── stack-verify.md
├── templates/
│   └── project/
│       ├── docs/TECH_STACK.md
│       ├── docs/PROJECT_STACK.md
│       └── .cursor/rules/
│           ├── generic/                   # always copied
│           └── stacks/rails8/             # copied when stack: rails8
└── docs/standards/
    └── stacks/
        └── rails8/
            ├── technical-guideline.md
            └── ddd/
                ├── adoption-profiles.md
                └── ddd-first-reference.md
```

## TECH_STACK.md

Org-wide tooling and stack selection. Rarely edited per MVP; bump on Rails upgrade or ADR.

```markdown
# Tech Stack

## Stack
rails8                    # or: node-api, generic, …

## Architecture mode
none                      # or: ddd

## DDD reference (only when architecture mode: ddd)
docs/standards/stacks/rails8/ddd/

## Verify command
bin/ci                    # from stack pack

## Norms & safeguards (summary)
See .cursor/rules/ and docs/standards/stacks/<stack>/
```

Detection defaults in `using-project-standards`:

| Signal | Default stack |
|--------|---------------|
| `Gemfile` contains `rails` | `rails8` |
| `package.json` with express/fastify | `node-api` |
| Neither | `generic` |

## PROJECT_STACK.md

Per-product decisions. Human-approved at bootstrap; updated when entity catalog or architecture mode changes.

Sections:

- Product summary, core user loop, roles
- Architecture mode (`none` | `ddd`)
- Entity catalog (living registry)
- Bounded contexts + profiles table (only when `architecture: ddd`)
- Context map (only when DDD)
- Enabled add-ons, out of scope, open TBCs

### Entity catalog (always — even without DDD)

| Entity | Module/Context | Description |
|--------|----------------|-------------|
| Order | orders | Purchase record |

New entities discovered during a feature must be added to this catalog before implementation begins.

### DDD table (only when architecture: ddd)

| Context | Subdomain | Owner | Profile | Overrides | ADR |
|---------|-----------|-------|---------|-----------|-----|

## Rules vs skills

| Concern | Mechanism |
|---------|-----------|
| Always-on coding norms | `.cursor/rules/*.mdc` (30–80 lines each) |
| Bootstrap + pre-dev gate | `using-project-standards` skill |
| Requirements + entity impact + design | `brainstorming` skill |
| Implementation tasks + DDD applicability | `writing-plans` skill |
| Hard proof | CI command from `TECH_STACK` |

Generic rule files (always copied):

- `project-non-negotiables.mdc` (`alwaysApply: true`)
- `project-testing.mdc` (glob: test paths per stack)

Stack pack adds file-specific rules (e.g. Rails: controllers, models, services).

Each rule header:

```markdown
Read docs/PROJECT_STACK.md for product and entity context.
Read docs/TECH_STACK.md for stack and architecture mode.
For full detail: docs/standards/stacks/<stack>/
```

## Skill: using-project-standards

```yaml
name: using-project-standards
description: Use when starting work in a project, scaffolding a new MVP, or when
  docs/TECH_STACK.md or docs/PROJECT_STACK.md is missing — before brainstorming
  or writing code.
```

### Hard gate

Do not invoke `brainstorming`, `writing-plans`, or `test-driven-development` until this skill completes and the human approves `PROJECT_STACK.md`.

### Checklist

1. Detect stack from repo files (`stack-detection.md`).
2. If `TECH_STACK.md` missing → copy template, set stack and verify command.
3. If `PROJECT_STACK.md` missing → scaffold from template.
4. Copy `.cursor/rules/` (generic + stack pack).
5. Copy `docs/standards/stacks/<stack>/` (technical guideline always for known stacks).
6. If `architecture mode: ddd` → also copy `ddd/` reference pack.
7. Interactive fill: product summary, seed entity catalog (2–5 entities), architecture mode.
8. If DDD → bounded contexts table (can start minimal, refine later).
9. Human approves `PROJECT_STACK.md`.
10. Announce completion; hand off to `brainstorming` for first feature or wait.

Announce: *"I'm using the using-project-standards skill to verify this project is ready."*

## Skill extensions

### brainstorming

Add after "Explore project context":

1. Read `TECH_STACK.md` and `PROJECT_STACK.md`.
2. If entity catalog empty → seed during intake questions.
3. Before design approval → produce **Entity impact** section:

```markdown
## Entity impact

| Entity | Module/Context | Impact | Operations |
|--------|----------------|--------|------------|
| Order | orders | primary | create, update |

## Relationships touched
- Order → User (belongs_to)

## Adjacent (not modified)
- Invoice (out of scope)

## Risks
- Cross-module write to accounts table
```

4. If DDD enabled → add **Contexts involved** section listing bounded contexts touched.
5. New entities → update `PROJECT_STACK.md` catalog before implementation.
6. Write spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
7. Human approves spec → invoke `writing-plans`.

### writing-plans

Inputs: approved design spec, `TECH_STACK`, `PROJECT_STACK`, stack reference paths.

**When `architecture mode: none`:**

- Stack placement section referencing `docs/standards/stacks/<stack>/` (e.g. technical-guideline §3 for Rails).
- Tasks tag: module, entities, files.

**When `architecture mode: ddd`:**

Insert **DDD applicability** section before tasks (from `ddd-applicability-template.md`):

```markdown
## DDD applicability (this feature)

**Reference docs** (read on demand — do not duplicate in this plan):
- docs/standards/stacks/rails8/ddd/adoption-profiles.md
- docs/standards/stacks/rails8/ddd/ddd-first-reference.md

**Contexts touched**

| Context | Subdomain | Profile | Layers used this feature |
|---------|-----------|---------|--------------------------|
| Billing | Core | Pragmatic | L0+L1: aggregate, domain events, outbox |

**Placement rules (from profile)**

| Profile | This plan uses |
|---------|----------------|
| Pragmatic | app/services/billing/, AR aggregate, outbox |

**Boundaries**
- No cross-context table writes; read via published query/ACL

**Out of scope for DDD this feature**
- L2 repositories, L4 event sourcing (not in profile)
```

Each task when DDD:

```markdown
### Task N: ...
- Context: Billing
- Profile: Pragmatic
- Entities: Bill (create), Customer (read via Accounts ACL)
- Pattern: application service → aggregate → outbox
- Reference: adoption-profiles.md (Pragmatic row)
- Files: ...
```

Target size for DDD applicability: 30–80 lines, not full standard text.

Human approves plan before TDD.

### verification-before-completion

Read `TECH_STACK` verify command. For `rails8`: run `bin/ci`. For other stacks: command named in `TECH_STACK`. Profile-scaled gates deferred to stack pack phase 5.

## End-to-end flows

### Project bootstrap (all stacks)

```
Session start → using-superpowers (existing hook)
User: "Build X" + missing stack files
  → using-project-standards
  → human approves PROJECT_STACK.md
  → ready for features
```

### Per feature (all stacks)

```
brainstorming (+ entity impact)
  → human approves design spec
writing-plans (+ DDD applicability if enabled)
  → human approves plan
test-driven-development
  → subagent-driven-development | executing-plans
verification-before-completion
  → requesting-code-review
  → finishing-a-development-branch
```

### Rails MVP (architecture mode: none) — typical

- `TECH_STACK`: `stack: rails8`, `architecture mode: none`
- References: `technical-guideline.md` only
- Plans: stack placement, no DDD section
- Verify: `bin/ci`

### Rails MVP (architecture mode: ddd) — opt-in

- Additional references: `stacks/rails8/ddd/*`
- `PROJECT_STACK`: contexts + profiles table
- Plans: DDD applicability section + per-task context/profile tags
- Same verify chain; profile-scaled fitness tests deferred

### Non-Rails (e.g. node-api)

- `TECH_STACK`: `stack: node-api`
- No Rails or DDD docs unless mode is `ddd` and node DDD pack exists
- Same skill chain; different rules templates and verify command

### Promoting to DDD later

1. Update `TECH_STACK` and `PROJECT_STACK` (`architecture mode: ddd`, contexts table).
2. Run `using-project-standards` copy step for `ddd/` pack only (or manual copy).
3. ADR recommended.
4. Next feature plans include DDD applicability; no workflow rewrite.

## SPDD influence (minimal)

Adopted:

- Entity impact before implementation (E — Entities, lightweight).
- Versioned design spec as intent artifact.
- Human approval gates (existing Superpowers).
- Fix spec/plan before code when behavior intent changes.

Not adopted:

- Full REASONS Canvas seven-part artifact tree.
- Separate analysis / canvas / sync / prompt-update skills.
- openspdd CLI.
- API tests before unit tests ordering change.

## Golden rules (team)

1. No feature work without approved design spec (includes entity impact).
2. No implementation without approved plan.
3. Fix spec/plan first when behavior intent changes — then code.
4. Rails engineering norms → `technical-guideline.md` reference; DDD not default.
5. DDD → opt-in via `PROJECT_STACK`; reference pack when enabled.
6. Done = verify command green per `TECH_STACK`.

## Implementation phases

| Phase | Deliverable | Outcome |
|-------|-------------|---------|
| 1 | `templates/project/` + generic rules | Bootstrap files exist |
| 2 | `using-project-standards` skill | Pre-dev gate works |
| 3 | Extend `brainstorming` (entity impact) | Per-feature entity table |
| 4 | Extend `writing-plans` (stack + DDD applicability) | Plans stack-aware |
| 5 | Rails8 stack pack (technical guideline + rails rules) | Rails MVPs supported |
| 6 | Rails8 DDD reference pack (`ddd/`) | Opt-in DDD for Rails |
| 7 | `verification-before-completion` stack verify ref | Done = CI green |
| 8 | Profile-scaled fitness tests in rails template | Hard DDD boundary enforcement (defer until needed) |

Phases 1–5 deliver a working Rails MVP workflow. Phase 6 adds DDD references. Phase 8 optional.

## Success criteria

- New Rails repo: agent runs `using-project-standards`, scaffolds files, stops for approval, then brainstorms with entity impact.
- New feature on existing repo: skips bootstrap, goes straight to brainstorming.
- `architecture mode: none` plan has no DDD section.
- `architecture mode: ddd` plan has DDD applicability with links, not pasted standards.
- Non-Rails repo uses same skills with different `TECH_STACK` stack value.
- `.cursor/rules/` active during editing; full guidelines remain in `docs/standards/`.

## Open decisions (resolved in this spec)

| Decision | Resolution |
|----------|------------|
| Rails vs generic workflow | Generic workflow; Rails is a stack pack |
| DDD as default? | No; opt-in via architecture mode |
| Full SPDD? | No; entity impact only |
| DDD in plans? | Applicability section + links, not full docs |
| Canonical TECH_STACK master | Fork template; per-repo copy (option A) |
| New skills count | One: `using-project-standards` |
