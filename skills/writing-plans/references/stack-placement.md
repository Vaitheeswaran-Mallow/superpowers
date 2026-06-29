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
