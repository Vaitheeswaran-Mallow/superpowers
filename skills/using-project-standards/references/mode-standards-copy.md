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
