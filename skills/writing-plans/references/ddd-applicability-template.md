# DDD applicability (insert before tasks when architecture mode: ddd)

Copy this section into the plan. Link to reference docs — do not paste full standards.

```markdown
## DDD applicability (this feature)

**Reference docs** (read on demand — do not duplicate in this plan):
- docs/standards/stacks/<stack>/ddd/adoption-profiles.md
- docs/standards/stacks/<stack>/ddd/ddd-first-reference.md

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

## Per-task tags (when DDD on)

Each task includes:
- **Context:** e.g. Billing
- **Profile:** e.g. Pragmatic
- **Entities:** e.g. Bill (create), Customer (read via Accounts ACL)
- **Pattern:** e.g. application service → aggregate → outbox
- **Reference:** adoption-profiles.md (profile row)

Target: 30–80 lines for the applicability section total.
