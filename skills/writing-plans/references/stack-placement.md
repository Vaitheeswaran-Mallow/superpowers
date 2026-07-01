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
