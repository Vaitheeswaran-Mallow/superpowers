# Architecture & Domain-Driven Design Standard

**Companion to the Rails 8 Technical Guideline.** This is our standing, project-agnostic standard for **macro-architecture and domain modelling**. It sits *alongside* the Technical Guideline the way an external reference (ISO/IEC 25010, AWS Well-Architected) does: the Guideline owns the application-layer rules; this document owns **how the domain is carved and modelled**. The two are read together; neither restates the other.

**Status:** A living standard, versioned and centrally maintained. Projects **do not fork it** — they record which parts they adopt, per bounded context, in their project addendum (see §10). Propose changes via PR + ADR.

**Targets:** Rails 8 **Technical Guideline v1.4**. When the Guideline is revised, this companion is re-checked against it and its version recorded; projects note both adopted versions in their addendum (§10).

**Relationship to the Technical Guideline.** This document **adds** strategic and tactical domain structure and **defers** every cross-cutting concern to the Guideline. It does not duplicate privacy, security, resilience, testing, observability, auth, or governance rules — it references them. Where this document and the Guideline appear to overlap, **the Guideline wins on the cross-cutting concern and this document wins on domain shape.**

| This document owns | The Technical Guideline owns |
|--------------------|------------------------------|
| Bounded contexts, ubiquitous language, context maps | Privacy (§11), Security (§10) |
| Subdomain classification (core / supporting / generic) | Third-party resilience (§9) |
| Aggregates, entities, value objects, invariants | Auth & Authorization (§4–§5) |
| Domain services vs application services | Database rules (§12), Performance (§14) |
| Domain events, projections, read models | Testing baseline (§15), Quality gates (§16) |
| Repositories / persistence-ignorance (optional) | Observability (§20), Error handling (§19) |
| CQRS and Event Sourcing (optional, per context) | Tech debt (§17), Governance (§21) |

> Throughout, **§N** refers to a section of the Technical Guideline; **§A.N** refers to its Add-On Catalog; layer references (**L0–L4**) are defined in §3 of *this* document.

---

## 1. First Principles

1. **Omakase remains valid.** Plain Rails — thin controllers, balanced models, service objects (Guideline §3) — is the correct default for most contexts. DDD is adopted **where domain complexity earns it**, not by default.
2. **Decoupleable adoption.** Every construct here is **opt-in and independently adoptable, per bounded context.** A project may run strategic DDD across the board, tactical patterns in two contexts, and event sourcing in exactly one — while another context stays pure omakase. **No layer forces the layer above it.** In particular, CQRS and Event Sourcing are separable from each other.
3. **The domain model is the asset.** Architecture exists to keep the **core subdomain** changeable and the language unambiguous. Effort concentrates there; generic subdomains stay cheap.
4. **Boundaries before patterns.** Get bounded contexts and the ubiquitous language right first (L0). Tactical patterns (L1+) are worthless across a wrong boundary.
5. **Reference, don't restate.** When a rule is cross-cutting, this document points at the Guideline rather than copying it, so the two never drift.

---

## 2. When to Apply DDD

DDD is a cost. Spend it where the domain is the hard part, not the plumbing.

**Classify each subdomain first:**

| Subdomain type | Definition | Default architecture |
|----------------|-----------|----------------------|
| **Core** | The reason the product wins; complex, differentiating business rules | DDD justified — L0 always; L1+ as complexity demands |
| **Supporting** | Necessary, specific to us, but not differentiating | L0 for naming/boundaries; L1 only if logic is non-trivial; otherwise omakase |
| **Generic** | Solved problems (auth, file storage, notifications) | Omakase or a bought/library solution; **no DDD ceremony** |

**Adopt DDD constructs when** the domain has rich invariants, multiple stakeholders disagree on terms, business rules change often under product/legal pressure, or several aggregates must stay transactionally consistent. **Skip them when** the context is CRUD over a stable schema — forcing aggregates there produces ceremony without payoff (see §11 anti-patterns).

---

## 3. The Adoption Model — Decoupleable Layers

Adoption is expressed as **layers chosen per bounded context** and recorded in the addendum (§10). Higher layers require lower ones *within that context*; they never apply globally.

| Layer | Adds | Requires | Relative cost | Default stance |
|-------|------|----------|---------------|----------------|
| **L0 — Strategic** | Bounded contexts, ubiquitous language, context map, subdomain classification, anti-corruption layers | — | Low (mostly design discipline) | **Recommended** for any non-trivial product |
| **L1 — Tactical on ActiveRecord** | Aggregates (AR-backed), value objects, domain services, domain events, factories | L0 | Low–med | Per core/complex-supporting context |
| **L2 — Persistence-ignorant models** | Repositories returning POROs; AR confined behind the repository | L1 | Med | Only when AR-as-aggregate genuinely constrains the model |
| **L3 — CQRS read models** | Explicit read side, projections, audience-specific read models | L1 (L2 optional) | Med | When read and write shapes diverge sharply |
| **L4 — Event Sourcing** | Event-sourced aggregates, event store, rebuild/snapshot | L1 (L2 optional, L3 common but **not required**) | High | Defer by default; adopt per context only with a clear driver |

**Independence rules (the decoupling contract):**

- **L1 is the floor** for any tactical work; L2, L3, L4 each layer onto L1 *independently*.
- **L3 does not require L4**, and **L4 does not require L3.** You can have event-sourced writes with simple AR-projected reads, or CQRS read models over a classic state-stored aggregate.
- **L2 is orthogonal** to L3/L4 — a repository can front a state-stored *or* event-sourced aggregate.
- A context can be **downgraded** (e.g. retire L4 back to state-stored) via an ADR and a migration; nothing in a higher layer is allowed to leak into another context.

### Evolving a context's layers
Layers are adopted incrementally; **start at the lowest layer that meets today's need and move up only when a driver appears.** Retrofit cost rises sharply with the layer:

| Move | Cost | Notes |
|------|------|-------|
| Omakase → **L0** | Low | Naming + boundaries; mostly a refactor of namespaces and a glossary |
| L0 → **L1** | Low–med | Add aggregates/value objects/events onto existing AR; behaviour migrates off services onto roots incrementally |
| L1 → **L2** | Med | Introduce repositories context-by-context; can be done one aggregate at a time behind the interface |
| L1 → **L3** | Med | Add read models alongside existing reads; **backfill** projections from current state (see §7) |
| L1/L3 → **L4** | **High** | Event sourcing is the expensive retrofit — introduce per context with a parallel-run/backfill plan, never big-bang |

**Rules for moving up:** record the move and its driver in an ADR (§10); migrate **one context at a time**; keep the old path working until the new one is verified (parallel run for L3/L4). Moving down a layer is equally ADR-gated. *Retrofitting an existing (non-DDD) codebase is governed by the onboarding standard — out of scope here.*

---

## 4. L0 — Strategic Design

### Bounded contexts
A bounded context is a boundary inside which **one model and one language are internally consistent.** The same word may mean different things in two contexts (a "User" in Identity ≠ a "User" in Billing); that is expected and healthy. Name contexts after the business capability, not the data table.

### Ubiquitous language
Each context maintains an explicit glossary (in the context's README or `docs/contexts/<name>.md`). **Code uses the glossary's terms** — class, method, and event names match the language the domain experts use. Translations between contexts happen only at boundaries, never silently.

### Context mapping
Document how contexts relate; the relationship dictates the integration pattern:

| Relationship | Use when | Rails realization |
|--------------|----------|-------------------|
| **Anti-Corruption Layer (ACL)** | Protecting a clean model from a messy upstream / external provider | An **adapter** (Guideline §3, §9) translating to local terms — the default for third-party providers |
| **Customer–Supplier / Conformist** | One context depends on another's model | Published interface + integration tests as the contract |
| **Shared Kernel** | Two contexts share a small, stable model deliberately | A shared module — kept minimal, changed only by joint agreement |
| **Open Host / Published Language** | A context serves many consumers | Versioned API surface (Guideline §A13) + stable event schema |
| **Separate Ways** | Integration costs more than it's worth | No coupling; duplicate the little that's needed |

### Context → deployment
**Default: a modular monolith** — one Rails app, one database, contexts isolated by namespacing and discipline, not network boundaries. This keeps transactions, tests, and refactoring cheap. **Split a context into its own service only** when it has a divergent scaling profile, an independent release cadence, or a hard data-isolation requirement — and record the split in an ADR. Premature service-splitting produces a distributed monolith (§11).

**Realization in Rails:** namespaced modules (`Billing::`, `Verification::`) for context boundaries; **Rails engines** are an option for hard isolation but are not required and add ceremony — reach for them only when namespacing proves insufficient. Cross-context calls go through a **published interface or a domain event**, never by reaching into another context's models.

### Context ownership (Conway's law)
A bounded context should have **one owning team** accountable for its model, language, and published interface. Align context boundaries with team boundaries: a context owned by two teams drifts in language; a team spread thin across many contexts can't keep any of them coherent. Record the owning team per context in the addendum (§10) — this is also the hook into the org-wide RACI/process framework. Cross-team changes to a context's **published** interface/events follow the customer–supplier contract (§4), not direct edits.

### Data ownership within the monolith
One database does **not** mean shared tables. Each table is **owned by exactly one context**, which alone **writes** it; other contexts may **read** it only through the owner's published interface, query object, or a read model (§7) — never by writing it or by joining across the boundary in domain code. Name tables with the context's namespace where practical, and treat a second context writing another's table as a boundary violation caught by the fitness tests (§9).

---

## 5. L1 — Tactical Design on ActiveRecord

The pragmatic default: model the domain **with** ActiveRecord, not against it. AR is the persistence *and* the entity; behaviour lives on it.

| Construct | Definition | Rails realization |
|-----------|-----------|-------------------|
| **Entity** | Identity-bearing object with a lifecycle | An AR model with behaviour (not just associations/validations) |
| **Value object** | Immutable, equality-by-value, no identity (Money, Address, DateRange, Score) | `composed_of`, a custom `ActiveRecord::Type`, or a frozen PORO; `normalizes` for canonical form |
| **Aggregate** | A consistency boundary; a cluster of objects treated as one unit | A root AR model that owns its children and exposes intent-revealing methods; **outside code touches only the root** |
| **Aggregate root** | The single entry point enforcing the aggregate's invariants | The root model; children are not loaded or mutated directly from other code |
| **Domain service** | Business logic that doesn't belong to one entity | A PORO in the context namespace (stateless, named for the operation) |
| **Application service** | Use-case orchestration, transaction boundary, event dispatch | A **service object** (Guideline §3) — `Orders::Place`, `Identities::Verify` |
| **Domain event** | A fact that happened in the domain | Emitted via the **Event Reporter** (Guideline §22, §20); handlers async + idempotent via Solid Queue |
| **Factory** | Encapsulated construction of a valid aggregate | A class method on the root or a dedicated factory PORO |

### Invariants
Enforce business invariants **inside the aggregate root** (the model that owns them). Keep the **database constraints from Guideline §12** (NOT NULL, FKs, unique/partial indexes, checks) as the **backstop** — the aggregate is the intent, the DB is the guarantee. Don't push invariant logic into controllers or scattered services.

### Concurrency
The aggregate root is the **concurrency boundary**. Protect concurrent edits with **optimistic locking** — `lock_version` on the root (Guideline §12) — so two writers can't both pass an invariant against stale state and produce an inconsistent commit. Application services translate a stale-write conflict (`StaleObjectError`) into a retry or a clear user-facing message (Guideline §9, §19), never a swallowed failure. For event-sourced aggregates, the equivalent control is **expected-version on append** (see §8).

### Aggregate sizing
Design **small** aggregates. The default is **one entity per aggregate**; pull another entity inside the boundary **only** when a true business invariant must hold across both atomically. Everything else is a separate aggregate, referenced by ID and kept consistent **eventually** via events. Prefer many small consistency boundaries over one large one — large aggregates create lock contention, slow loads, and the god-aggregate anti-pattern (§11).

### Aggregate boundaries
- One transaction commits **one aggregate**; cross-aggregate consistency is achieved **eventually**, via domain events + idempotent handlers (Guideline §9, §22) — not by widening a transaction across roots.
- Reference other aggregates **by ID**, not by object graph (mirrors Guideline §7's "pass IDs to jobs").
- An aggregate that needs another aggregate's data uses a **query/read model**, not a direct association reaching across the boundary.

### Domain errors
Model rule violations as **explicit domain failures**, not generic exceptions or booleans. Two acceptable shapes — pick one per context and stay consistent:
- **Raised domain exceptions** — a small hierarchy (e.g. `Verification::Rejected`, `Billing::InsufficientFunds`) the application service rescues and maps to a user-facing message/status (Guideline §19's controlled rescue hierarchy). Truly unexpected errors still propagate to the error tracker.
- **Result objects** — operations return a success/failure result the caller inspects; no exceptions for expected business outcomes.

Either way: **expected business rejections are not 500s.** Validation/permission/state failures map to the correct status and a clear message; only genuine faults hit error tracking (Guideline §19, §20).

### Event naming
Domain events are **named in the past tense** for facts that happened (`OrderPlaced`, `TenantVerified`, `ScoreRecomputed`), carry a stable id and the minimum payload consumers need, and use the context's ubiquitous language. Commands (imperative) are distinct from events (past tense).

### Anti-corruption
External providers and other contexts are reached only through an **adapter / ACL** (Guideline §3, §9) that translates foreign shapes into this context's language. No provider SDK type crosses into the domain model.

### Reliable event publishing
Domain events drive cross-aggregate and cross-context consistency, so an event must be published **if and only if** its aggregate's transaction commits — never the dual-write trap of "save the record, then enqueue the job" (a crash between the two silently loses the event).

- **Write the event in the same database transaction as the aggregate** — a transactional **outbox**: an `outbox_events` (or domain-events) row committed atomically with the state change.
- A **relay** (a recurring Solid Queue job, Guideline §7) reads unpublished outbox rows and dispatches them to the **Event Reporter** (Guideline §20, §22) / their handlers, marking them published. At-least-once delivery is expected.
- **Consumers dedupe** on the event's stable id (an **inbox**/processed-ids check) and are **idempotent** (Guideline §9) — they tolerate duplicate and out-of-order delivery.
- The Guideline's **reconciliation sweep** (§9) backstops the relay: it detects events stuck unpublished or handlers that never converged.

> Adopt the outbox the moment a context's events cross an aggregate or context boundary. Within a single aggregate's transaction, ordinary callbacks are fine.

### Coordinating long-running work — process managers
Point-to-point events handle one fact → one reaction. A workflow that spans **several aggregates or contexts** and must reach an outcome (verify → score → notify; reserve → charge → confirm) needs a **process manager** (saga): a stateful coordinator that listens for events, issues the next command, and tracks the workflow's own state.

- Each step is an **idempotent** command against one aggregate; the process manager advances on the resulting event (Guideline §9 resilience patterns apply per step).
- Model **compensation**, not distributed transactions: when a later step fails unrecoverably, emit compensating commands to undo or neutralize earlier steps (e.g. release a hold, void a charge), or route to **manual review** (Guideline §A3) — never leave a half-finished workflow.
- Long pipelines use **`ActiveJob::Continuable`** (Guideline §7, §A3) so a restart resumes mid-workflow rather than re-running completed steps.
- The process manager is itself an aggregate (it has identity, state, and invariants) and is tested as one (§9 of this document).

---

## 6. L2 — Persistence-Ignorant Models (optional)

Adopt only when AR-as-aggregate **measurably** constrains the model — e.g. an aggregate whose invariants don't map to a single table, or a core domain you want unit-testable with zero database.

- Define a **repository interface** per aggregate that returns **domain objects (POROs)**, hiding AR entirely.
- AR lives **inside** the repository as the persistence detail; the rest of the context depends on the interface, not on `ActiveRecord::Base`.
- **Cost:** you give up "free" AR features (scopes, encryption, `lock_version`, `normalizes`) at the domain boundary and must re-provide what you need. Budget for it.
- This is the layer that most diverges from omakase — keep it confined to the contexts that earn it; **do not make it a house style.**

---

## 7. L3 — CQRS Read Models (optional)

Separate the **write model** (aggregates that enforce invariants) from **read models** (shapes optimized for queries and for specific audiences).

- The write side stays as L1 (or L2/L4). The read side is **projections**: denormalized tables, query objects (Guideline §3), or cached views built from domain events.
- **Audience-specific read models** are the natural home for role-/stage-sensitive output — they compose with **presenters/serializers and policies** (Guideline §5, §A8), not replace them.
- Projections are rebuilt from events or domain writes by **idempotent Solid Queue handlers** (Guideline §7, §9).
- **Decoupling:** L3 works over a **state-stored** aggregate just as well as an event-sourced one. CQRS here means "separate read and write shapes," **not** "event sourcing." Adopt it for read/write divergence alone.
- **Bootstrapping a projection:** a new read model is **backfilled** from current state (or replayed from the event stream under L4) before it goes live; backfill jobs are idempotent and resumable (`ActiveJob::Continuable`, Guideline §7).
- **Lag is an operational signal:** projections are eventually consistent, so **monitor projection/outbox lag** (oldest unprocessed event age) and alert on a threshold (Guideline §20). Stuck projections are caught by the reconciliation sweep (Guideline §9).
- **Read-after-write staleness:** because the read side trails the write, a user can act and not immediately see their own change. Handle it deliberately — read the writer's own result from the write model (or an optimistic UI update via Turbo, Guideline §13) for the acting user, while others converge asynchronously. Never present stale reads as a dead end (Guideline §9 user-facing state).

---

## 8. L4 — Event Sourcing (optional, per context)

The highest-cost layer. The aggregate's state is **derived from an append-only stream of events** rather than stored as current-state rows.

**Adopt only with a concrete driver:** a legal/audit requirement for a complete, immutable history; complex temporal logic ("what did we know at time T"); or a need to derive many read models from one source of truth. **Default is to defer** — most contexts never need it, and retrofitting it later is far cheaper per-context than carrying it everywhere.

When adopted in a context:
- Events are the source of truth; current state is a **fold** over the stream. Add **snapshots** for performance once streams grow.
- **Concurrency: expected-version on append.** Appending to a stream carries the version the writer believed it was extending; a mismatch means a concurrent write occurred — reject and retry. This is the event-sourced equivalent of the aggregate `lock_version` in §5, and it is what keeps invariants safe without a current-state row to lock.
- **Event schema versioning (events are forever).** A stored event's shape will outlive the code that wrote it, so plan evolution from day one: events are **append-only and never edited in place**; make only **additive, backward-compatible** changes; and when a breaking change is unavoidable, introduce a **new event version** and an **upcaster** that translates old events to the current shape on read. Version the event type (e.g. `name` + `version`), and keep upcasters covered by tests (§9 of this document). When an upcaster changes how state is derived, **invalidate affected snapshots** so they rebuild from upcast events. This discipline also governs the **published** event schema other contexts depend on (§4).
- Read models (L3) are projections off the stream — this is where L3 and L4 commonly meet, though **neither requires the other**.
- **Alignment with the audit log (Guideline §22):** the event stream can *be* the audit trail for that context, but the Guideline's append-only audit and PII-read logging obligations still apply at their boundaries.
- **Immutability vs. erasure (privacy):** an immutable stream collides with deletion/erasure duties (Guideline §11, and any Compliance pack §A15). Resolve with **crypto-shredding** — store erasable PII referenced by key, drop the key to render events unreadable — rather than rewriting history. Document the approach in the context's ADR and compliance appendix.

**Decoupling guarantee:** event sourcing stays **inside its context**. Its events are an internal representation; other contexts integrate via the context's **published events/interface** (L0), never by reading its event store.

---

## 9. Domain-Shaped Testing & Architecture Enforcement

The **testing baseline is Guideline §15** — this document adds only the domain-specific tests below; it does not restate coverage, policy, request, or system-test rules.

| Test | Asserts |
|------|---------|
| **Aggregate invariant** | The root rejects every state that violates a business rule; valid transitions succeed |
| **Value object** | Equality-by-value, immutability, normalization |
| **Domain event** | The right event is emitted with the right payload on each significant transition |
| **Context contract** | A context's published interface/events match what consumers depend on (the customer–supplier contract, §4) |
| **Projection (L3/L4)** | Rebuilding a read model/state from events is deterministic and idempotent |
| **Reliable publishing** | An event is in the outbox iff its transaction committed; consumers dedupe on event id (§5) |
| **Process manager** | The saga reaches its outcome on the happy path and compensates correctly on step failure (§5) |
| **Event upcasting (L4)** | An upcaster maps each prior event version to the current shape; old streams still fold (§8) |

### Enforce the boundaries — don't rely on discipline
The boundary rules in this standard (context isolation, data ownership, no cross-context model leakage) **degrade silently unless a test fails the build when they're broken.** Make them executable:

- **Architecture-fitness test** — a CI check (a custom RSpec, or a tool such as **`packwerk`/`packs`**) that asserts: no context references another context's internal models; cross-context access goes only through published interfaces/events; and each table is written by its owning context only (§4 data ownership). A violation **fails `bin/ci`** (Guideline §16), not a code review.
- **Dependency direction** (DDD-first deployments) — where a layered package structure is used, the same tooling enforces that dependencies point inward.
- **Consumer-driven contracts** — when a context is split into its own service, the customer–supplier contract becomes a **consumer-driven contract test** so a producer change that breaks a consumer fails CI.

Tooling is a recommendation, not a mandate — a hand-written boundary spec is acceptable; what's mandatory is that **the boundary is checked automatically**.

---

## 10. Per-Context Adoption Record

Adoption lives in the **project addendum** defined by Guideline §1 — extended with a per-context table. **Do not edit this standard per project.**

**Context map addendum** (in `docs/PROJECT_CONTEXT.md` or `docs/contexts/`):

| Bounded context | Subdomain type | Owner team | Layers adopted | Key relationships | ADR |
|-----------------|----------------|-----------|----------------|-------------------|-----|
| *e.g. Verification* | Core | Trust & Safety | L0, L1, L4 | ACL → Certn; events → Matching | `adr/0007` |
| *e.g. Billing* | Supporting | Payments | L0, L1 | Customer–supplier → Accounts | `adr/0008` |
| *e.g. Notifications* | Generic | Platform | — (omakase) | Conformist | — |

**Governance:** adopting or changing a layer in a context is an **ADR-worthy decision** (Guideline §21) — record the driver, the layer, the scope (which context), and a revisit trigger. Splitting a context into a service is likewise an ADR.

---

## 11. Anti-Patterns (do not ship)

- **Anemic aggregate** — an AR model with no behaviour, all logic in procedural services. If you adopt L1, behaviour belongs on the model.
- **DDD ceremony on a generic subdomain** — aggregates and events over plain CRUD. Use omakase (§2).
- **Leaking AR across a context boundary** — exposing another context's models instead of its published interface/events (§4).
- **God aggregate** — one root owning half the schema; widening transactions across what should be separate consistency boundaries (§5).
- **Event sourcing by default** — adopting L4 without a driver, or letting one context's event store be read by another (§8).
- **CQRS conflated with ES** — assuming read/write separation requires an event store (§7).
- **Dual-write event publishing** — saving the aggregate and enqueuing its event in two steps; use the transactional outbox (§5).
- **Orphaned saga** — a multi-step workflow with no compensation or manual-review path, leaving half-finished state on failure (§5).
- **Editing stored events** — mutating an event in place instead of versioning + upcasting (§8).
- **Distributed monolith** — splitting contexts into services prematurely, then coupling them synchronously (§4).
- **Shared-table writes** — a second context writing another context's table, or joining across the boundary in domain code instead of going through the published interface (§4 data ownership).
- **Unenforced boundaries** — relying on review/discipline for context isolation instead of an automated fitness test in `bin/ci` (§9).
- **Ownerless / shared-owned context** — a context with no single owning team, or split across two, so its language drifts (§4).
- **Oversized aggregate** — pulling entities inside a boundary without a true cross-entity invariant; prefer small aggregates referenced by ID (§5).
- **Stale read as dead end** — surfacing an eventually-consistent projection to the acting user as if it were authoritative, with no own-write read-back or optimistic update (§7).
- **Forking this standard or the Guideline per project** — adoption is recorded in the addendum, not by rewriting the standard (§10).

---

## 12. Quick Reference

```
✓ Classify subdomains first: core (DDD) · supporting (selective) · generic (omakase)
✓ One owning team per context (Conway) · each table written by its owner only
✓ L0 boundaries + ubiquitous language before any tactical pattern
✓ Adopt layers PER CONTEXT · higher layer needs lower · never global · move up only on a driver
✓ L3 (CQRS) and L4 (ES) are independent of each other
✓ Design SMALL aggregates · one entity unless a true shared invariant
✓ Aggregates enforce invariants · DB constraints (§12) are the backstop
✓ Model domain errors explicitly · business rejections are not 500s
✓ One transaction = one aggregate · cross-aggregate consistency via events (§22)
✓ Optimistic locking on the aggregate root · expected-version on ES append
✓ Publish events via transactional OUTBOX · consumers dedupe + idempotent (§9)
✓ Domain events named past-tense · stable id · minimum payload
✓ Multi-step cross-aggregate work = process manager + compensation, not 2PC
✓ ES events are append-only · version + upcast · invalidate snapshots on upcast
✓ Backfill new projections · monitor projection/outbox lag · handle read-after-write
✓ Reference other aggregates/contexts by ID or published interface — never object graph
✓ ACL/adapter at every external + cross-context boundary (§5)
✓ ES stays inside its context · crypto-shred to reconcile immutability vs erasure (§8)
✓ ENFORCE boundaries with an architecture-fitness test in bin/ci — not discipline (§9)
✓ Record context map + owner + adopted layers in the project addendum · ADR per decision
✗ No anemic aggregates · No DDD on generic subdomains · No cross-context model leakage
✗ No ES by default · No premature service split · No forking the standard
✗ No dual-write publishing · No orphaned sagas · No editing stored events
✗ No shared-table writes · No unenforced boundaries · No ownerless contexts · No stale dead-ends
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| **1.0** | 2026-06-26 | Completeness pass (final for this cycle). Added: layer **evolution/retrofit** guidance with cost table (§3); **context ownership** (Conway) and **data/table ownership** within the monolith (§4); **aggregate sizing** heuristics, **domain-error** modelling, **event-naming** convention (§5); projection **backfill**, **lag monitoring**, **read-after-write** handling (§7); **snapshot invalidation** on upcasting (§8); **architecture-fitness tests**, boundary tooling, consumer-driven contracts (§9, renamed *Testing & Architecture Enforcement*); **owner-team** column in the adoption record (§10); new anti-patterns and quick-reference lines; **Guideline v1.4 version pin**; Appendix A **glossary** and Appendix B **worked example**. |
| **0.2 (draft)** | 2026-06-26 | Load-bearing reliability/consistency controls: optimistic concurrency + expected-version on append (§5, §8); transactional **outbox** with inbox/dedupe (§5); **process managers / sagas** with compensation (§5); event **schema versioning + upcasting** (§8). Matching testing rows and anti-patterns. |
| **0.1 (draft)** | 2026-06-26 | Initial sibling Architecture & DDD standard. Decoupleable L0–L4 adoption model; strategic + tactical DDD on ActiveRecord; optional repository, CQRS, and event-sourcing layers; per-context adoption record extending the Technical Guideline addendum. |

---

## Appendix A — Glossary

| Term | Meaning in this standard |
|------|--------------------------|
| **Bounded context** | A boundary inside which one model and one ubiquitous language are internally consistent |
| **Ubiquitous language** | The shared, precise vocabulary of a context, used identically by domain experts and in code |
| **Subdomain** | A part of the business problem space; classified core / supporting / generic to decide how much architecture it earns |
| **Context map** | The documented set of relationships between bounded contexts |
| **Anti-corruption layer (ACL)** | An adapter that translates a foreign model (external provider or another context) into the local language |
| **Entity** | A domain object with identity and a lifecycle |
| **Value object** | An immutable object compared by value, with no identity |
| **Aggregate** | A consistency boundary treated as one unit; mutated only through its root |
| **Aggregate root** | The single entry point that enforces an aggregate's invariants |
| **Invariant** | A business rule that must always hold for an aggregate |
| **Domain service** | Stateless domain logic that doesn't belong to a single entity |
| **Application service** | Use-case orchestration; the transaction boundary and event-dispatch point (a service object) |
| **Domain event** | A past-tense fact emitted when something significant happens in the domain |
| **Outbox** | A table written in the same transaction as the aggregate so events publish iff the transaction commits |
| **Process manager / saga** | A stateful coordinator of a multi-step workflow across aggregates/contexts, with compensation |
| **Projection / read model** | A read-optimized shape derived from writes or events (CQRS read side) |
| **CQRS** | Separating the write model from read models; independent of event sourcing |
| **Event sourcing (ES)** | Storing state as an append-only stream of events; current state is a fold over the stream |
| **Upcaster** | A function that translates an older event version to the current shape on read |
| **Crypto-shredding** | Rendering stored data unreadable by destroying its encryption key, used to reconcile immutability with erasure |
| **Architecture-fitness test** | An automated CI check that fails the build when an architectural boundary rule is violated |

---

## Appendix B — Worked Example: one context through the layers

A compact illustration of how a single core context (`Verification`) is realized. Illustrative, not prescriptive.

- **L0 — Strategic.** `Verification` is a **core** subdomain owned by *Trust & Safety*. Ubiquitous language: *Applicant, Check, Verdict, TrustScore*. Relationships: **ACL → Certn** (provider); **publishes** `ApplicantVerified` consumed by `Matching` (customer–supplier).
- **L1 — Tactical.** Aggregate root `Verification::Applicant` owns its `Check`s and enforces the invariant "a `Verdict` is final only when all required `Check`s have passed." `TrustScore` is a **value object** (`composed_of`). Application service `Verification::RunChecks` opens the transaction, calls the domain, writes the **outbox** event `ApplicantVerified`. Concurrency via `lock_version` on the root. A `Verification::Rejected` **domain error** maps to a 422, not a 500.
- **Reliability.** The Certn call lives in `Verification::CertnAdapter` (ACL) with timeout, backoff+jitter, circuit breaker, idempotency key (Guideline §9). The verify → score → notify flow is a **process manager** that compensates (release hold) if scoring fails.
- **L3 — CQRS (adopted).** A `LandlordFacingApplicant` **read model** exposes only the fields a landlord may see, composing with a presenter + policy; backfilled on launch; projection lag monitored.
- **L4 — ES (adopted, this context only).** `Applicant` is event-sourced for an immutable verification history; **expected-version on append**; PII in events is **crypto-shredded** on erasure; events **versioned + upcast**. `Billing` and `Notifications` remain plain omakase — ES does not leak out of `Verification`.
- **Enforcement.** A fitness test fails CI if any other context references `Verification::Applicant` directly or writes its tables.

---

*Architecture & DDD Standard — v1.0 · companion to the Rails 8 Technical Guideline v1.4 (project-agnostic).*
