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
