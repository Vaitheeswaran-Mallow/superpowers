# Rails 8 DDD — Adoption Profiles

**Read this first.** This is the third candidate structure for adopting DDD. Where the **Architecture & DDD Standard** offers layers *à la carte* (maximum flexibility, more decisions) and the **DDD-First Edition** imposes one mandatory architecture (maximum consistency, higher floor), **Adoption Profiles trade fine-grained choice for low decision-cost**: a team picks a named preset and gets a coherent, pre-reasoned bundle — without deciding each layer from scratch.

**Relationship to the substrate.** Profiles are **presets over the layer model** (L0–L4) and constructs defined in the **Architecture & DDD Standard v1.0**, with cross-cutting rules from the **Rails 8 Technical Guideline v1.4**. This document defines the **presets and how to select them** — not the layer mechanics. For *how* the outbox, upcasting, crypto-shredding, repositories, or fitness tests actually work, see the substrate; this document says *which* of them a given profile turns on.

**Decoupling preserved.** Selecting a profile never forces event sourcing or CQRS. Even the heaviest profile keeps **L4 (event sourcing) and L3 (CQRS) opt-in per context and independent of each other** — a "Full DDD" project event-sources only the contexts with a concrete driver.

**Governance unchanged.** Profile selection and any per-context override are recorded in the project addendum; overrides and profile changes are ADR-worthy. Projects don't fork this document.

---

## 1. How Selection Works

- A project picks **one baseline profile** as its default posture.
- Each **bounded context** either **inherits** the baseline or **overrides** to a different profile, recorded in the addendum (§6). An override is an **ADR** (driver, context, chosen profile).
- Profiles therefore apply **per context** with a project-level default — this is what keeps adoption coarse and cheap *and* keeps heavy machinery confined to the contexts that need it.

> **What never varies by profile.** The cross-cutting non-negotiables — security, privacy, third-party resilience, authentication/authorization, database integrity, testing baseline, observability, governance (Technical Guideline §4–§21) — are **identical under every profile**. Profiles vary **domain architecture only**, never the guarantees. "Omakase" is not "less safe"; it is "less domain ceremony."

---

## 2. The Profiles

### Omakase
**Intent:** plain Rails, the framework's defaults, no DDD ceremony. **When:** generic subdomains, simple supporting contexts, CRUD over a stable schema, MVPs and spikes.

- **Structure:** thin controllers → service objects → balanced ActiveRecord models (Technical Guideline §3). Bounded-context naming is encouraged but informal; no formal aggregates, no required domain events.
- **Layers:** none formally (informal L0 at most). L1–L4 off.
- **Events:** only where a genuine integration need appears — then adopt the outbox locally (substrate §5).
- **Cost:** lowest. **Risk if misused:** a genuinely complex core outgrows it and logic sprawls across services.

### Pragmatic DDD
**Intent:** most of DDD's structural value at low cost — the recommended default for non-trivial products. **When:** core subdomains of typical complexity and supporting contexts with real logic.

- **Structure:** **L0 strategic** (bounded contexts, ubiquitous language, context map, ownership) + **L1 tactical on ActiveRecord** (aggregates with behaviour, value objects, domain services, domain events via the transactional outbox, process managers where workflows span aggregates).
- **Layers:** L0 + L1 **baseline**. **L3 (CQRS)** adopted **per context where read and write shapes diverge**. **L2 (repositories)** and **L4 (event sourcing)** by **exception only**, each with an ADR and a driver.
- **Events:** outbox + idempotent consumers standard.
- **Cost:** medium. **Best risk/reward** for most teams.

### Full DDD
**Intent:** the heavyweight posture for complex, core-heavy, audit/compliance-driven domains. **When:** rich-invariant core subdomains; regulatory history/audit requirements; many read models from one source of truth.

- **Structure:** L0 + L1 as baseline; **L2 (persistence-ignorant domain)** for core contexts that earn it; **L3 (CQRS)** standard on core read paths; **L4 (event sourcing)** on contexts with a concrete driver.
- **Layers:** L0 + L1 + L2 baseline for **core** contexts; L3 standard on core reads; **L4 still per-context and decoupleable** (never "event-source everything"). Generic contexts in a Full-DDD project may still run lighter via override.
- **Enforcement:** strict — the dependency rule and boundaries are enforced by fitness tests in `bin/ci` (§5).
- **Cost:** highest. **Risk if misused:** ceremony and slowed delivery on contexts that didn't need it.

### Comparison matrix

| | **Omakase** | **Pragmatic DDD** | **Full DDD** |
|---|---|---|---|
| **L0 strategic** | Informal | Baseline | Baseline |
| **L1 tactical (AR)** | — | Baseline | Baseline |
| **L2 repositories** | — | By exception (ADR) | Core contexts |
| **L3 CQRS** | — | Where read/write diverge | Standard on core reads |
| **L4 event sourcing** | — | By exception (ADR) | Per context with a driver *(decoupleable)* |
| **Domain events + outbox** | Only if needed | Standard | Standard |
| **Process managers/sagas** | — | Where workflows span aggregates | Yes |
| **Enforcement (fitness tests)** | Minimal | Boundaries + data ownership | + dependency rule + projection determinism |
| **Decision cost** | Lowest | Medium | Highest |
| **Best for** | Generic / CRUD / MVP | Most core + real-logic supporting | Complex core / audit / compliance |
| **Cross-cutting non-negotiables** | Identical | Identical | Identical |

---

## 3. Choosing a Profile (per context)

Map each context's **subdomain class and signals** to a profile:

- **Omakase** when: generic subdomain; CRUD over a stable schema; few invariants; no cross-aggregate consistency needs; speed-to-ship dominates.
- **Pragmatic DDD** when: rich invariants or evolving business rules; multiple stakeholders disagree on terms; workflows span a few aggregates; you want structure without persistence-ignorance or event-store cost. *(Default when unsure for a non-trivial context.)*
- **Full DDD** when: a differentiating core with deep invariants; a legal/audit requirement for immutable history; complex temporal logic; or many read models from one source.

**Heuristic:** pick the project baseline for the *typical* context, then override the outliers. A product with one complex core and several CRUD contexts is usually **Pragmatic DDD baseline**, with the core context overridden to **Full DDD** and the CRUD contexts to **Omakase**.

---

## 4. Evolving Between Profiles

Profiles are **starting postures, not cages.** A context moves **Omakase → Pragmatic → Full** (or back) as its complexity changes — one context at a time, ADR-gated, never a big-bang. The cost of each move is the layer-evolution cost in the substrate (§3 of the Architecture & DDD Standard): L0→L1 low–med, →L2/L3 medium (backfill projections), →L4 high (parallel-run per context). Keep the old path working until the new one is verified.

A per-context override is the same mechanism as evolution: it is recorded with its driver and a revisit trigger, so profiles stay honest rather than aspirational.

---

## 5. Enforcement by Profile

What the architecture-fitness tests (substrate §9 / DDD-First §8) assert scales with the profile:

| Profile | Enforced in `bin/ci` |
|---------|----------------------|
| **Omakase** | Standard Technical Guideline gates (RuboCop, Brakeman, bundler-audit, RSpec ≥80%, Bullet). No domain-boundary checks. |
| **Pragmatic DDD** | + context isolation (no cross-context model leakage) + **data ownership** (one writer per table) + domain tests (aggregate invariants, domain events, reliable publishing, sagas). |
| **Full DDD** | + **dependency rule** (inward-only) where layered packages are used + projection determinism + event-upcaster tests + consumer-driven contracts for any service-split context. |

Enforcement is automated, not by discipline — a violation **fails the build**, scoped to what the context's profile promises.

---

## 6. Per-Context Profile Record

Recorded in the project addendum (extending Technical Guideline §1) — **not** in this document.

**Project baseline profile:** *e.g. Pragmatic DDD*

| Bounded context | Subdomain | Owner team | Profile | Overrides / optional layers | ADR |
|-----------------|-----------|-----------|---------|------------------------------|-----|
| *Verification* | Core | Trust & Safety | **Full DDD** (override) | L4 event-sourced; L2 repositories | `adr/0007` |
| *Billing* | Supporting | Payments | Pragmatic (baseline) | L3 read models | `adr/0008` |
| *Matching* | Core | Discovery | Pragmatic (baseline) | — | — |
| *Notifications* | Generic | Platform | **Omakase** (override) | — | `adr/0009` |

Selecting the baseline, and every override, is an **ADR-worthy decision** (driver, context, profile, revisit trigger).

---

## 7. Anti-Patterns (do not ship)

- **Full DDD on a CRUD context** — aggregates, repositories, and an event store over plain create/update. Override to Omakase.
- **Omakase on a complex core** — rich invariants smeared across service objects with no aggregate to own them. Promote to Pragmatic/Full.
- **Profile as a cage** — refusing a justified per-context override to stay "pure" to the baseline. The override mechanism exists precisely for this.
- **Override sprawl** — every context on a different profile with no recorded driver; profiles should cluster, with overrides justified.
- **Varying the non-negotiables by profile** — relaxing security, privacy, resilience, or testing because a context is "just Omakase." Those never vary (§1).
- **Event-sourcing a whole Full-DDD project** — L4 is per-context with a driver even under Full DDD; defaulting it everywhere is the substrate's "ES by default" anti-pattern.
- **Forking this document or the substrate per project** — selection lives in the addendum.

---

## 8. Quick Reference

```
✓ Project picks ONE baseline profile · each context inherits or overrides (ADR)
✓ Profiles = presets over the L0–L4 layer model (see Architecture & DDD Standard v1.0)
✓ Omakase = plain Rails · Pragmatic = L0+L1 (+L3 where divergent) · Full = +L2/L3 (+L4 by driver)
✓ ES (L4) and CQRS (L3) stay opt-in PER CONTEXT and independent — even under Full DDD
✓ Cross-cutting non-negotiables are IDENTICAL under every profile — domain ceremony varies, guarantees don't
✓ Pick baseline for the typical context · override the outliers · record owner + profile in addendum
✓ Evolve Omakase → Pragmatic → Full per context · ADR-gated · one at a time · parallel-run for L3/L4
✓ Enforcement scales with profile · automated in bin/ci · fails the build
✗ No Full DDD on CRUD · No Omakase on a complex core · No profile-as-cage · No override sprawl
✗ Never relax the non-negotiables by profile · Never ES-by-default · Never fork the standard
```

---

## Appendix A — Glossary

Profile-specific terms; for layer/construct definitions (aggregate, outbox, upcaster, crypto-shredding, etc.) see the Architecture & DDD Standard v1.0 glossary.

| Term | Meaning |
|------|---------|
| **Profile** | A named preset bundling a coherent set of layer/tactical choices a context adopts |
| **Baseline profile** | The project-wide default profile a context inherits unless overridden |
| **Override** | A context running a different profile from the baseline, recorded with an ADR |
| **Omakase / Pragmatic DDD / Full DDD** | The three profiles, from least to most domain ceremony |
| **Non-negotiables** | Cross-cutting rules identical under every profile (security, privacy, resilience, testing, governance) |

---

## Appendix B — Worked Example: one project, three profiles

A two-sided marketplace, **baseline Pragmatic DDD**:

- **Verification** (core, Trust & Safety) → **Full DDD** override. Persistence-ignorant `Applicant` aggregate (L2), event-sourced for immutable history (L4, expected-version + crypto-shredding), landlord read model (L3). Strict dependency-rule enforcement. *Driver: regulatory audit history.*
- **Billing** (supporting, Payments) → **Pragmatic** (baseline). AR aggregates with behaviour, value objects, domain events via outbox, a `Statement` read model (L3) because the billing read shape diverges from the write model. No repositories, no event store.
- **Matching** (core, Discovery) → **Pragmatic** (baseline). Rich aggregates and a verify→score→notify process manager; no ES (no history driver yet — may evolve to Full DDD later via ADR).
- **Notifications** (generic, Platform) → **Omakase** override. Plain controllers + service objects + AR models; an outbox added only for the one cross-context event it consumes.

Every context — Omakase included — enforces the same security, privacy, resilience, and testing non-negotiables.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| **1.0** | 2026-06-26 | Initial Adoption Profiles standard: Omakase / Pragmatic DDD / Full DDD presets over the L0–L4 substrate; per-context selection with a project-level baseline and ADR-gated overrides; comparison matrix; selection guide; profile evolution; profile-scaled enforcement; per-context profile record; anti-patterns; glossary and worked example. Built on Architecture & DDD Standard v1.0 + Technical Guideline v1.4. |

*Rails 8 DDD Adoption Profiles — v1.0 · candidate structure (project-agnostic) · presets over Architecture & DDD Standard v1.0.*
