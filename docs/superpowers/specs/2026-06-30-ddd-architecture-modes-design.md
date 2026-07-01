# DDD Architecture Modes & Package-First Rails Layout

Extend the project-standards integration with three architecture modes, ship the missing Architecture & DDD companion standard, and enforce package-first bounded-context layout so agents stop generating conventional flat Rails structure when DDD is enabled.

**Status:** Approved design — ready for implementation plan  
**Builds on:** [2026-06-29-project-standards-integration-design.md](2026-06-29-project-standards-integration-design.md)  
**Date:** 2026-06-30

## Problem

Teams enabling `architecture mode: ddd` still get conventional Rails layout (`app/models/user.rb`, flat services) because:

1. DDD reference docs describe **conceptual layers**, not **on-disk package structure**.
2. Cursor rules use omakase language and point at `technical-guideline.md` regardless of mode.
3. Bootstrap copies docs but does not scaffold `app/domains/` or Zeitwerk collapse config.
4. Plans tag context/profile but do not mandate full file paths with layer tags.
5. The **Architecture & DDD Standard** (companion to the Technical Guideline) is referenced by adoption-profiles as “substrate” but is not shipped in `docs/standards/`.

Agents default to training-data Rails conventions; load-on-demand standards in `docs/standards/` are often skipped during codegen.

## Goals

- Three explicit architecture modes in `TECH_STACK.md`, not a binary `none | ddd`.
- Ship `architecture-and-ddd-standard.md` in the fork DDD pack for `ddd-companion` mode.
- `ddd-first` mode copies only `ddd-first-reference.md` (replaces topic-organized guideline in the app repo).
- Package-first layout: `app/domains/<context>/{domain,application,infrastructure,interface}/`.
- Interface layer inside the package (`interface/` subfolder) — not split to `app/controllers/`.
- Bootstrap scaffolds package dirs, `docs/contexts/` glossaries, and `config/initializers/zeitwerk.rb`.
- Cursor rules and plan templates enforce paths agents must follow.

## Non-goals

- Packwerk / `packs/` migration (future, aligns with package-first).
- Automated architecture-fitness test in `bin/ci` (follow-up spec).
- Rewriting prose of existing standards beyond path references and README.
- Upstream Superpowers PR (fork-specific).
- Changing root-level `Architecture_and_DDD_Standard.md` / `Rails8_DDD_First_Standard.md` except as copy sources.

## Locked decisions

| Decision | Choice |
|----------|--------|
| Architecture modes | `none`, `ddd-companion`, `ddd-first` |
| `ddd-first` standards in app | `ddd-first-reference.md` only — no `technical-guideline.md` |
| `ddd-companion` standards in app | `technical-guideline.md` + `architecture-and-ddd-standard.md` + `adoption-profiles.md` |
| Code organization | Package-first under `app/domains/<context>/` |
| Interface placement | Inside package: `app/domains/<context>/interface/` |
| Documentation glossaries | `docs/contexts/<name>.md` (bounded context terminology) |
| Ruby module naming | Flat per context: `Billing::Invoice` (not `Billing::Domain::Invoice`) |
| Zeitwerk | Collapse layer subfolders so constants stay flat |
| Legacy `architecture mode: ddd` | Normalize to `ddd-companion` on bootstrap |

## Terminology

| Term | Meaning |
|------|---------|
| `app/domains/<context>/` | Bounded-context **package** (business area) — not “the domain layer” |
| `…/domain/` | Domain **layer** folder inside the package (aggregates, value objects) |
| `…/application/` | Application layer (use cases, sagas) |
| `…/infrastructure/` | Adapters, repositories (L2), read models (L3) |
| `…/interface/` | Controllers, presenters, channels for this context |
| Bounded context | Strategic DDD boundary — recorded in `PROJECT_STACK.md` |

## Architecture modes

### `none`

- **Standards copied:** `docs/standards/stacks/rails8/technical-guideline.md`
- **Rules:** generic + rails8 omakase (`rails-controllers.mdc`, `rails-models.mdc`, `rails-services.mdc`)
- **Layout:** conventional Rails — no `app/domains/`

### `ddd-companion`

- **Standards copied:** `technical-guideline.md` + `ddd/architecture-and-ddd-standard.md` + `ddd/adoption-profiles.md` + `ddd/rails-package-layout.md`
- **Rules:** omakase rails rules + `rails8-ddd-structure.mdc` + `rails8-ddd-companion.mdc`
- **Spine:** Topic-organized Technical Guideline + domain companion (L0–L4 adoption model)
- **Per-context profiles:** Omakase / Pragmatic / Full DDD (from adoption-profiles)
- **Layout:** Package-first for contexts on Pragmatic or Full profile; Omakase contexts may use conventional paths

### `ddd-first`

- **Standards copied:** `ddd/ddd-first-reference.md` + `ddd/rails-package-layout.md` only
- **Rules:** `rails8-ddd-structure.mdc` + `rails8-ddd-first.mdc` (no omakase model language)
- **Spine:** Four-layer architecture (Interface / Application / Domain / Infrastructure) mandatory for every context
- **Per-context column:** Tactical depth (not profile presets)
- **Layout:** Every bounded context gets full package with all four layer subfolders

## Package-first layout

### Per-context tree

```
app/domains/billing/
├── domain/
│   ├── invoice.rb                 # Billing::Invoice
│   └── money.rb                   # Billing::Money
├── application/
│   ├── record_usage.rb            # Billing::RecordUsage
│   └── dunning_process.rb         # Billing::DunningProcess (saga)
├── infrastructure/
│   ├── adapters/stripe_adapter.rb
│   ├── repositories/              # L2 only
│   └── read_models/               # L3 only
└── interface/
    ├── invoices_controller.rb     # Billing::InvoicesController
    └── invoice_presenter.rb

docs/contexts/billing.md             # ubiquitous language glossary
```

### Hard rules

- No flat `app/models/<entity>.rb` for entities owned by a bounded context when package applies.
- No provider SDK calls outside `app/domains/<context>/infrastructure/adapters/`.
- No business logic in interface layer — delegate to application service → domain.
- Cross-context access only via published query/ACL or domain events — never direct internal model references.
- Routes use `namespace :billing` mirroring the context name.

### Construct → path mapping

| Construct | Path |
|-----------|------|
| Controller | `app/domains/<context>/interface/` |
| Presenter | `app/domains/<context>/interface/` |
| Application service | `app/domains/<context>/application/` |
| Saga / process manager | `app/domains/<context>/application/` |
| Aggregate / entity / VO | `app/domains/<context>/domain/` |
| Adapter (ACL) | `app/domains/<context>/infrastructure/adapters/` |
| Repository (L2) | `app/domains/<context>/infrastructure/repositories/` |
| Read model (L3) | `app/domains/<context>/infrastructure/read_models/` |
| Context-owned job | `app/domains/<context>/application/` (e.g. `Billing::ProcessInvoiceJob`) |

### Shared (non-context-owned) infrastructure

```
app/models/outbox_event.rb
app/jobs/outbox_relay_job.rb
```

Allowlist for top-level models when `ddd-first`: `application_record.rb`, `outbox_event.rb` only.

### Zeitwerk collapse (required)

Ship `config/initializers/zeitwerk.rb` in bootstrap templates:

```ruby
# config/initializers/zeitwerk.rb
%w[domain application infrastructure interface].each do |layer|
  Dir[Rails.root.join("app/domains/*/#{layer}")].each do |path|
    Rails.autoloaders.main.collapse(path)
  end
end

%w[adapters repositories read_models].each do |sub|
  Dir[Rails.root.join("app/domains/*/infrastructure/#{sub}")].each do |path|
    Rails.autoloaders.main.collapse(path)
  end
end
```

This maps `app/domains/billing/domain/invoice.rb` → `Billing::Invoice`, not `Billing::Domain::Invoice`.

## TECH_STACK.md

```markdown
## Architecture mode
none                    # or: ddd-companion, ddd-first

## Standards reference
<!-- none: docs/standards/stacks/rails8/technical-guideline.md -->
<!-- ddd-companion: docs/standards/stacks/rails8/ + docs/standards/stacks/rails8/ddd/ -->
<!-- ddd-first: docs/standards/stacks/rails8/ddd/ddd-first-reference.md -->
```

Legacy value `ddd` → normalize to `ddd-companion` in `using-project-standards`.

## PROJECT_STACK.md

### Bounded contexts table

| Context | Subdomain | Owner | Profile / Depth | Overrides | ADR |
|---------|-----------|-------|-----------------|-----------|-----|

- **`ddd-companion`:** use **Profile** column (Omakase / Pragmatic / Full DDD).
- **`ddd-first`:** use **Tactical depth** column (thin / moderate / deep).

Bootstrap creates package scaffold only for contexts that require it (all contexts for `ddd-first`; Pragmatic/Full for `ddd-companion`).

## Bootstrap flow (`using-project-standards`)

When `architecture mode` is `ddd-companion` or `ddd-first`:

1. Copy standards per mode table above.
2. Copy DDD Cursor rules per mode.
3. For each bounded context row requiring a package:
   - Create `app/domains/<context>/domain/.keep`
   - Create `app/domains/<context>/application/.keep`
   - Create `app/domains/<context>/infrastructure/adapters/.keep`
   - Create `app/domains/<context>/interface/.keep`
   - Create `docs/contexts/<context>.md` from glossary template
4. Copy `config/initializers/zeitwerk.rb` if not present.
5. Human approves `PROJECT_STACK.md` before feature work.

## Cursor rules (new / updated)

| File | When | Purpose |
|------|------|---------|
| `rails8-ddd-structure.mdc` | ddd-companion or ddd-first | Package tree, collapse note, anti-patterns (~50 lines) |
| `rails8-ddd-companion.mdc` | ddd-companion | Companion + profiles; Omakase exemption |
| `rails8-ddd-first.mdc` | ddd-first | ddd-first-reference; all contexts packaged |
| `rails-models.mdc` etc. | always for rails8 | Add note: superseded by ddd-structure when DDD mode on |

## Skills & plan templates

### `stack-placement.md`

- Document placement for `ddd-companion` and `ddd-first` separately.
- Reference `ddd/rails-package-layout.md`.

### `ddd-applicability-template.md`

- Mode-specific reference doc links.
- Mandatory per-task **Files** block with full package paths and layer tags:

```markdown
**Files:**
- app/domains/billing/application/record_usage.rb (Application)
- app/domains/billing/domain/invoice.rb (Domain)
- app/domains/billing/infrastructure/adapters/stripe_adapter.rb (Infrastructure)
```

### `entity-impact.md`

- When DDD on, entity rows may include package path prefix.

## Fork file changes

### Add

| Path | Source / content |
|------|------------------|
| `docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md` | From root `Architecture_and_DDD_Standard.md` |
| `docs/standards/stacks/rails8/ddd/rails-package-layout.md` | New — canonical layout + Zeitwerk + examples |
| `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-structure.mdc` | New |
| `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-companion.mdc` | New |
| `templates/project/.cursor/rules/stacks/rails8/rails8-ddd-first.mdc` | New |
| `templates/project/config/initializers/zeitwerk.rb` | New |
| `templates/project/docs/contexts/_template.md` | New glossary stub |

### Update

| Path | Change |
|------|--------|
| `docs/standards/stacks/rails8/ddd/README.md` | Three modes, file manifest per mode |
| `docs/standards/stacks/rails8/ddd/adoption-profiles.md` | Package paths; in-repo substrate link |
| `skills/using-project-standards/SKILL.md` | Three-mode copy + scaffold steps |
| `skills/using-project-standards/references/tech-stack-template.md` | Three modes |
| `skills/using-project-standards/references/project-stack-template.md` | Profile vs depth column note |
| `templates/project/docs/TECH_STACK.md` | Three modes |
| `templates/project/docs/PROJECT_STACK.md` | Profile / depth columns |
| `skills/writing-plans/SKILL.md` | Three modes |
| `skills/writing-plans/references/stack-placement.md` | Package paths |
| `skills/writing-plans/references/ddd-applicability-template.md` | Package paths + file mandate |
| `tests/project-standards/test-skill-structure.sh` | Assert new artifacts exist |

## Success criteria

After implementation, bootstrapping a greenfield Rails app with `architecture mode: ddd-first` produces:

1. `app/domains/<context>/{domain,application,infrastructure,interface}/` for each context in `PROJECT_STACK.md`
2. `config/initializers/zeitwerk.rb` with layer collapses
3. `docs/contexts/<context>.md` stubs
4. DDD Cursor rules active in `.cursor/rules/`
5. `writing-plans` output includes full package paths per task

An agent prompted to add a feature in context `Billing` places code under `app/domains/billing/` — not `app/models/billing/` or flat `app/models/`.

## Follow-ups (separate specs)

- Architecture-fitness RSpec in `bin/ci` (top-level model allowlist for ddd-first)
- Packwerk optional pack per `app/domains/<context>/`
- Eval: agent session with “add billing invoice” lands files in package paths
