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

4. If architecture mode is `ddd-companion` or `ddd-first`, add **Contexts involved** and optional **Package paths** (`app/domains/<context>/…`) per rails-package-layout.md
5. New entities → update `docs/PROJECT_STACK.md` catalog before implementation
