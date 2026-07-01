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
