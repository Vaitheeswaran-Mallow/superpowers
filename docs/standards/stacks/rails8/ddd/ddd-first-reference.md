# Rails 8 Engineering Standard — DDD-First Edition

**Read this first.** This is a candidate restructuring of our Rails 8 Technical Guideline in which **Domain-Driven Design is the organizing spine** rather than an add-on. The same mandatory rules apply — privacy, security, resilience, testing, governance — but they are arranged **by architectural layer** instead of by topic. If adopted, this edition *replaces* the topic-organized guideline; it does not sit beside it.

**What is baseline vs. optional.** Strategic design (bounded contexts, ubiquitous language, subdomain classification) and the **four-layer architecture** are the **baseline structure** every project follows. How much **tactical depth** a context takes, and whether it adopts the **optional architectural layers** (repositories, CQRS, event sourcing), is **decided per bounded context** and is fully **decoupleable** — nothing forces event sourcing or CQRS, and the two are independent of each other (§7).

**Governance unchanged.** Projects don't fork this document. They record per-context decisions in a project addendum and capture hard-to-reverse choices as ADRs (§9). Improvements flow back here via PR + ADR.

**Lineage & transition.** This edition derives from the **Rails 8 Technical Guideline v1.4** and the **Architecture & DDD Standard v1.0** (its substrate); a project adopts *either* the topic-organized guideline *or* this DDD-first edition, and records which in its addendum. A team already on the topic-organized guideline migrates incrementally — **carve contexts (§1) and adopt the layer names first, refactor logic into layers per context after**, one context at a time, never as a big-bang rewrite. Retrofitting an existing non-DDD codebase is governed by the (separate) onboarding standard.

**Rails baseline:** latest stable Rails 8 / 8.1, omakase stack (Solid trilogy, Hotwire-first, built-in auth generator, `params.expect`, Active Record encryption, Event Reporter, `config/ci.rb` + `bin/ci`).

---

## 1. Strategic Foundation *(baseline)*

Before code, carve the domain. This is mandatory structure, not an optional pack.

- **Bounded contexts.** Partition the system into contexts, each with one internally-consistent model and language. Name them after business capabilities (`Verification`, `Billing`, `Matching`), not tables. The same word may mean different things in two contexts — expected and healthy.
- **Ubiquitous language.** Each context keeps a glossary (`docs/contexts/<name>.md`); class, method, and event names use those exact terms. Translation between contexts happens only at boundaries.
- **Subdomain classification** drives how much architecture each context earns:

| Subdomain | Definition | Tactical depth |
|-----------|-----------|----------------|
| **Core** | Differentiating, complex business rules | Full domain layer; optional layers as drivers demand |
| **Supporting** | Necessary, specific, not differentiating | Light domain layer where logic is non-trivial; otherwise omakase |
| **Generic** | Solved problems (auth, storage, notifications) | Omakase or bought solution; **no DDD ceremony** |

- **Context map.** Document how contexts relate (ACL, customer–supplier, conformist, shared kernel, open-host/published-language, separate-ways). The relationship dictates the integration: external providers and cross-context calls go through an **ACL/adapter** (§6); never reach into another context's models.
- **Context ownership (Conway's law).** Each context has **one owning team** accountable for its model, language, and published interface; align context boundaries with team boundaries. Record the owner per context in the addendum (§9) — this is the hook into the org-wide RACI/process framework.
- **Data ownership.** One database does **not** mean shared tables: each table is **owned and written by exactly one context**; others **read** it only through a published interface, query object, or read model (§7) — never write it or join across the boundary in domain code. Boundary violations are caught by the fitness tests (§8), not code review.
- **Deployment default: modular monolith.** One Rails app, one database, contexts isolated by **namespacing and discipline**. Split a context into a service only with a divergent scaling/release/isolation driver — recorded in an ADR. Premature splitting yields a distributed monolith (§10).

---

## 2. The Layered Architecture *(the spine)*

Every context is structured in four layers. The **dependency rule** is absolute: **dependencies point inward.** The Domain layer depends on nothing; the Interface and Infrastructure layers depend on the inside, never the reverse.

```
        ┌─────────────────────────────────────────────┐
        │  INTERFACE   controllers · Hotwire · views   │
        │              serializers · channels · API    │
        ├─────────────────────────────────────────────┤
        │  APPLICATION application services · sagas    │
        │              command/query handlers · policy │
        ├─────────────────────────────────────────────┤
        │  DOMAIN      aggregates · entities · VOs      │
        │  (the heart) domain services · domain events │   ← depends on nothing
        ├─────────────────────────────────────────────┤
        │  INFRASTRUCTURE  AR persistence · adapters    │
        │                  Solid trilogy · outbox relay │
        └─────────────────────────────────────────────┘
              dependencies point inward  ↑↑↑
```

**Pragmatic exception (omakase-friendly):** in the default Rails realization, the Domain layer is expressed *with* ActiveRecord — aggregates are AR models with behaviour. AR therefore appears to straddle Domain and Infrastructure. That is accepted by default; the **persistence-ignorant** split (true inward-only Domain) is the **optional L2 layer** (§7), taken only where a context earns it. The dependency *rule* still governs: no Interface concern (params, rendering) and no provider SDK type leaks into domain behaviour.

---

## 3. Interface Layer

HTTP and delivery only. Carries the Technical Guideline's interface rules.

- **Controllers stay thin** — params (`params.expect`), `authorize`, delegate to an application service, render/redirect. No business logic, no provider calls. *(carried: Guideline §3)*
- **Hotwire-first** — Turbo Drive/Frames/Streams before custom JS; Stimulus for behaviour; handle `turbo:fetch-request-error` with retry UI. **WCAG 2.1 AA** mandatory; `axe-core` on key flows. *(carried: §13)*
- **Presenters / serializers** are the **sole render path** for role- or stage-sensitive output — field-level visibility is enforced here, never by UI hiding. *(carried: §3, §A8)*
- **Channels (Solid Cable)** authorize every subscriber in `#subscribed`. *(carried: §6)*
- **Error surface** — branded 404/422/500, structured JSON error bodies, no stack traces in production. *(carried: §19)*

---

## 4. Application Layer

Use-case orchestration and the transaction boundary. This is the only layer that coordinates multiple aggregates or contexts.

- **Application services** (service objects) orchestrate one use case, open the transaction, invoke the domain, and dispatch events. `Identities::Verify`, `Orders::Place`. *(carried: §3)*
- **Authorization** is invoked here and at the interface boundary — policy per resource, allow- and deny-tested. *(carried: §5)*
- **Process managers / sagas** coordinate multi-step workflows across aggregates/contexts, advancing on events and **compensating** on unrecoverable failure (or routing to manual review). Long pipelines use `ActiveJob::Continuable`. *(see §7 cross-aggregate consistency; Guideline §9, §A3)*
- **Command / query handlers** appear here when a context adopts CQRS (§7); otherwise application services serve both.
- **Background work** — Solid Queue; pass IDs not records; idempotent jobs; retries with backoff at the job layer. *(carried: §7, §9)*
- **Reliable event dispatch** — events are written to the **transactional outbox** inside the use-case transaction and relayed asynchronously; consumers dedupe and are idempotent (§7). *(carried: §9, §22)*
- **Domain errors** — expected rule violations are modelled explicitly (a small domain-exception hierarchy *or* result objects, consistent per context) and mapped here to the correct status/message; **business rejections are not 500s**, only genuine faults reach error tracking (*carried: §19, §20*).

---

## 5. Domain Layer *(the heart)*

Where the business rules live. Pure of HTTP, persistence mechanics, and provider SDKs (within the omakase exception of §2).

| Construct | Rails realization |
|-----------|-------------------|
| **Entity** | AR model (or PORO under L2) with behaviour and a lifecycle |
| **Value object** | `composed_of` / custom `ActiveRecord::Type` / frozen PORO; `normalizes` for canonical form |
| **Aggregate + root** | A root that owns its children and exposes intent-revealing methods; **outside code touches only the root** |
| **Domain service** | Stateless PORO for logic spanning entities |
| **Domain event** | A fact emitted via the Event Reporter; handlers async + idempotent |
| **Factory** | Encapsulated construction of a valid aggregate |

- **Invariants** are enforced inside the aggregate root; **DB constraints (§6 / Guideline §12) are the backstop** — aggregate is intent, DB is guarantee.
- **Concurrency:** the root is the concurrency boundary — **optimistic locking** (`lock_version`); event-sourced aggregates use **expected-version on append** (§7).
- **Boundaries:** one transaction commits one aggregate; reference other aggregates **by ID**; cross-aggregate consistency is **eventual**, via events.
- **Aggregate sizing.** Design **small** aggregates — one entity per aggregate by default; include another only when a true invariant must hold across both atomically. Everything else is a separate aggregate referenced by ID, consistent eventually via events. Prefer many small boundaries over one large one.
- **Domain events** are **past-tense** facts (`ApplicantVerified`, `OrderPlaced`) carrying a stable id and minimum payload, in the context's ubiquitous language; commands (imperative) are distinct from events.
- **Tactical depth dials here.** A supporting context may keep this layer thin (a couple of value objects, a single aggregate); a core context goes deep. This is the main knob for "how much DDD."

---

## 6. Infrastructure Layer

Persistence, providers, and framework plumbing. Implements interfaces the inner layers depend on.

- **Persistence** — ActiveRecord by default (migrations enforce integrity: NOT NULL, FKs, unique/partial/CHECK; index FKs and hot columns; always order + paginate; money in integer cents; UTC; no `default_scope`). *(carried: §12)*
- **Repositories** (optional, L2) — when a context needs persistence-ignorant domain objects, AR is confined behind a repository returning POROs (§7).
- **Adapters / ACL** — one per external provider; the **only** place provider SDKs are called. All adapters implement the resilience patterns: explicit timeouts, transient/permanent classification, backoff + jitter, per-provider circuit breaker, idempotency keys, dead-letter + alert, reconciliation sweep. *(carried: §9)*
- **Solid trilogy** — Solid Queue (jobs, recurring, outbox relay), Solid Cache (TTL'd fragment/collection caching), Solid Cable (authorized real-time). *(carried: §6, §7, §8)*
- **Outbox relay** — the recurring job that publishes committed outbox events; the reconciliation sweep backstops it (§7, §4).

---

## 7. Optional Architectural Layers *(decoupleable, per context)*

These extend the spine **per bounded context**. Each is opt-in, ADR-recorded, and independent except where noted. **CQRS and Event Sourcing are independent of each other.**

### L2 — Persistence-ignorant domain (repositories)
Adopt only when AR-as-aggregate measurably constrains the model. Repository returns POROs; AR lives inside it. You forgo "free" AR features (scopes, encryption, `lock_version`) at the boundary and re-provide what you need. The layer that most diverges from omakase — **never a house style**.

### L3 — CQRS read models
Separate the write model (aggregates) from read models (projections, query objects, audience-specific read models composing with presenters/policies). Projections rebuilt by idempotent Solid Queue handlers. **Works over a state-stored aggregate just as well as an event-sourced one** — CQRS means "separate read/write shapes," not "event sourcing." New projections are **backfilled** (from state, or replayed from the stream under L4) before going live; **projection/outbox lag is monitored** and alerted (§8, carried §20); **read-after-write** is handled for the acting user (own-write read-back or optimistic Turbo update) so a trailing read side is never a dead end.

### L4 — Event sourcing
State is a **fold** over an append-only event stream. Adopt only with a concrete driver (immutable history/audit, temporal logic, many read models from one source). Defer by default.
- **Expected-version on append** for concurrency; **snapshots** for performance.
- **Events are forever:** append-only, never edited; additive/backward-compatible changes preferred; breaking changes get a **new event version + upcaster** (tested); upcasters that change derivation **invalidate affected snapshots**. Governs the published event schema too.
- **Immutability vs. erasure:** resolve with **crypto-shredding** (erasable PII by key; drop the key), not history rewriting. *(carried: §11, §A15)*
- **Stays inside its context** — other contexts integrate via published events/interface, never the event store.

**Per-context independence:** L2/L3/L4 layer onto the baseline domain independently; downgrading a context (e.g. retiring L4) is an ADR + migration; no optional layer leaks into another context.

**Evolving a context.** Start at the baseline (strategic + four layers, thin tactical) and move up only on a driver. Retrofit cost rises with the layer: **L0→L1** low–med (behaviour migrates onto roots incrementally); **→L2** medium (introduce repositories one aggregate at a time); **→L3** medium (add read models, backfill projections); **→L4** **high** (event sourcing — parallel-run/backfill per context, never big-bang). Record each move and its driver in an ADR; migrate one context at a time; keep the old path working until the new one is verified.

---

## 8. Cross-Cutting Concerns *(span all layers)*

These don't belong to one layer — they apply throughout and are mandatory exactly as in the topic-organized guideline. Summarized here; the rules are unchanged.

| Concern | Rule (carried from Technical Guideline) |
|---------|------------------------------------------|
| **Security** | CSRF/CSP/security headers; secrets in credentials/ENV; rate-limit sensitive endpoints; validate uploads; Brakeman + bundler-audit before merge *(§10)* |
| **Privacy** | Data minimization; consent capture; append-only write audit + sensitive-read logging at presenter boundaries; encrypt PII at rest; retention in config; masked-by-default admin *(§11)* |
| **Authentication** | Rails 8 built-in generator baseline; `User` separate from `Identity`; OAuth/SSO/Devise via add-on *(§4)* |
| **Observability** | Structured logs + Event Reporter; request correlation id propagated into jobs and providers; `/up`; filtered params *(§20)* |
| **Testing** | §15/§16 baseline **plus domain tests**: aggregate invariants, value objects, domain events, context contracts, projections, reliable-publishing, sagas, upcasters *(§9 of the sibling standard)* |
| **Quality gates** | `bin/ci`: RuboCop + Brakeman + bundler-audit + RSpec (≥80%) + Bullet *(§16)* |
| **Environment & config** | Staging mirrors prod; credentials/ENV; idempotent seeds; no real PII in seeds *(§18)* |
| **Tech debt** | Tracked shortcuts; current deps/EOL; bounded complexity; quarantined flaky tests *(§17)* |
| **Governance** | Versioned standard; deviations need a time-boxed ADR; improvements flow upstream *(§21)* |

### Architecture enforcement (non-negotiable in this edition)
The dependency rule and context boundaries are this edition's spine, so they are **enforced automatically, not by discipline.** A CI check — a custom RSpec or a tool such as **`packwerk`/`packs`** — fails `bin/ci` when: a dependency points outward (Interface/Infrastructure concern or provider SDK type reaching into the Domain layer); one context references another's internal models instead of its published interface/events; or a context writes a table it doesn't own (§1 data ownership). When a context is split into a service, its customer–supplier contract becomes a **consumer-driven contract test**. Tooling is a recommendation; an automated check is mandatory.

---

## 9. Per-Context Adoption Record

Decisions live in the project addendum (extending the Technical Guideline's §1 template) — **not** in this document.

| Bounded context | Subdomain | Owner team | Tactical depth | Optional layers | Key relationships | ADR |
|-----------------|-----------|-----------|----------------|-----------------|-------------------|-----|
| *Verification* | Core | Trust & Safety | Deep domain | L4 | ACL → Certn; events → Matching | `adr/0007` |
| *Billing* | Supporting | Payments | Moderate | — | Customer–supplier → Accounts | `adr/0008` |
| *Notifications* | Generic | Platform | Omakase | — | Conformist | — |

Adopting/changing a layer or splitting a context is an **ADR-worthy decision** (driver, layer, scope, revisit trigger).

---

## 10. Anti-Patterns (do not ship)

- **Dependency-rule violation** — Interface concerns (params, rendering) or provider SDK types reaching into the Domain layer.
- **Anemic domain** — aggregates with no behaviour, logic pushed up into fat application services.
- **Fat application service** — business rules that belong on an aggregate living in orchestration code.
- **DDD ceremony on a generic subdomain** — aggregates/events over plain CRUD; use omakase.
- **Cross-context model leakage** — using another context's models instead of its published interface/events.
- **God aggregate** — one root owning half the schema; transactions widened across consistency boundaries.
- **Dual-write publishing** — saving the aggregate and enqueuing its event in two steps instead of the outbox.
- **Orphaned saga** — multi-step workflow with no compensation/manual-review path.
- **ES by default / editing stored events / cross-context event-store reads.**
- **CQRS conflated with ES.**
- **Distributed monolith** — premature service split with synchronous coupling.
- **Shared-table writes** — a context writing a table it doesn't own, or joining across the boundary in domain code (§1).
- **Unenforced boundaries** — relying on review instead of an architecture-fitness check in `bin/ci` (§8).
- **Ownerless / shared-owned context** — no single owning team, so the language drifts (§1).
- **Oversized aggregate** — entities pulled inside a boundary without a true shared invariant (§5).
- **Stale read as dead end** — surfacing an eventually-consistent projection to the acting user with no own-write read-back (§7).
- **Forking the standard per project** — adoption is recorded in the addendum, not by rewriting the standard (§9).

---

## 11. Quick Reference

```
✓ Strategic first: bounded contexts · ubiquitous language · subdomain class (baseline)
✓ One owning team per context (Conway) · each table written by its owner only
✓ Four layers · dependencies point INWARD · Domain depends on nothing
✓ Interface thin · Application orchestrates + transaction · Domain holds rules · Infra implements
✓ Tactical depth dials PER CONTEXT · optional L2/L3/L4 independent · CQRS ≠ ES · move up on a driver
✓ Design SMALL aggregates · one entity unless a true shared invariant
✓ Aggregates enforce invariants · DB constraints backstop · optimistic lock / expected-version
✓ Model domain errors explicitly · business rejections are not 500s
✓ One txn = one aggregate · reference by ID · eventual consistency via OUTBOX events
✓ Domain events past-tense · stable id · minimum payload
✓ Sagas + compensation for multi-step work · adapters/ACL at every external boundary
✓ ES events append-only · version + upcast · invalidate snapshots · crypto-shred for erasure
✓ Backfill new projections · monitor projection/outbox lag · handle read-after-write
✓ ENFORCE the dependency rule + boundaries with a fitness test in bin/ci — not discipline
✓ Cross-cutting (security/privacy/observability/testing/governance) unchanged, spanning layers
✓ Per-context record in addendum (context · owner · depth · layers) · ADR per decision
✗ No inward leakage · No anemic domain · No fat app services · No DDD on generic subdomains
✗ No dual-write · No orphaned sagas · No premature service split · No forking the standard
✗ No shared-table writes · No unenforced boundaries · No ownerless contexts · No stale dead-ends
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| **1.0** | 2026-06-26 | Completeness pass (final for this cycle). Added: lineage + **transition path** from the topic-organized guideline (header); **context ownership** (Conway) and **data/table ownership** (§1); **domain-error** modelling (§4); **aggregate sizing** + **event-naming** (§5); projection **backfill**, **lag monitoring**, **read-after-write** handling, and **layer-evolution** guidance (§7); **snapshot invalidation** on upcasting (§7 L4); **architecture-enforcement** subsection — fitness tests, boundary tooling, consumer-driven contracts (§8); **owner-team** column (§9); new anti-patterns and quick-reference lines; Appendix A **glossary** and Appendix B **worked example**. Substrate updated to Architecture & DDD Standard **v1.0**. |
| **0.1 (draft)** | 2026-06-26 | DDD-first restructuring of the Rails 8 Technical Guideline: strategic design + four-layer architecture as baseline spine; cross-cutting mandatory rules mapped onto layers; tactical depth and optional L2/L3/L4 layers decoupleable per bounded context. |

---

## Appendix A — Glossary

| Term | Meaning in this edition |
|------|--------------------------|
| **Bounded context** | A boundary inside which one model and one ubiquitous language are internally consistent |
| **Ubiquitous language** | The shared, precise vocabulary of a context, used identically by experts and code |
| **Subdomain** | A part of the problem space; core / supporting / generic, deciding how much architecture it earns |
| **Dependency rule** | Dependencies point inward; the Domain layer depends on nothing |
| **Layer** | Interface / Application / Domain / Infrastructure — the four-layer spine |
| **Anti-corruption layer (ACL)** | An adapter translating a foreign model (provider or another context) into the local language |
| **Entity / Value object** | Identity-bearing domain object / immutable value compared by value |
| **Aggregate / root** | A consistency boundary mutated only through its root, which enforces invariants |
| **Application service** | Use-case orchestration; the transaction boundary and event-dispatch point |
| **Domain event** | A past-tense fact emitted when something significant happens |
| **Outbox** | A table written in the aggregate's transaction so events publish iff it commits |
| **Process manager / saga** | Stateful coordinator of a multi-step workflow with compensation |
| **Projection / read model** | A read-optimized shape derived from writes or events (CQRS read side) |
| **CQRS / Event sourcing** | Separate read/write models / state stored as an append-only event stream (independent of each other) |
| **Upcaster** | Translates an older event version to the current shape on read |
| **Crypto-shredding** | Rendering stored data unreadable by destroying its key, to reconcile immutability with erasure |
| **Architecture-fitness test** | An automated CI check that fails the build on an architectural-boundary violation |

---

## Appendix B — Worked Example: one context through the four layers

`Verification` — a **core** context owned by *Trust & Safety*. Illustrative, not prescriptive.

- **Interface.** `Verification::ApplicantsController` — `params.expect`, `authorize`, delegates to an application service, renders via a presenter that exposes only landlord-visible fields.
- **Application.** `Verification::RunChecks` opens the transaction, invokes the domain, writes the **outbox** event `ApplicantVerified`; a `Verification::Rejected` **domain error** maps to 422. The verify → score → notify flow is a **process manager** that compensates (release hold) if scoring fails.
- **Domain.** Aggregate root `Applicant` owns its `Check`s and enforces "a `Verdict` is final only when all required `Check`s pass"; `TrustScore` is a **value object**; concurrency via `lock_version`. Small aggregate — `Check` lives inside `Applicant` because the invariant spans them; `Billing` is a separate aggregate referenced by ID.
- **Infrastructure.** `Verification::CertnAdapter` (ACL) is the only caller of the Certn SDK, with timeout/backoff/circuit-breaker/idempotency key (carried §9). `Verification` owns its tables; no other context writes them.
- **Optional layers (this context only).** **L3** `LandlordFacingApplicant` read model (backfilled, lag-monitored). **L4** event-sourced `Applicant` for immutable history — expected-version on append, PII crypto-shredded, events versioned + upcast. `Billing`/`Notifications` stay plain omakase; ES does not leak out.
- **Enforcement.** A fitness test fails `bin/ci` if another context references `Verification::Applicant` or writes its tables, or if an Interface/provider type reaches into the Domain layer.

---

*Rails 8 DDD-First Engineering Standard — v1.0 · candidate restructuring (project-agnostic) · derived from Technical Guideline v1.4 + Architecture & DDD Standard v1.0.*
