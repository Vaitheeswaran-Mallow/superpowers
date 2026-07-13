# Rails 8 Technical Guideline

**Read this first.** This is our standing technical standard for every Rails 8 application we build. Follow it during design, implementation, review, and local testing. It is not tied to any single project — projects adopt it as-is and record their specifics in a short project addendum (see §1).

**Status:** A living standard derived from production Rails 8 practices. It is maintained centrally and versioned; **projects do not fork or rewrite it per engagement** — they enable the add-ons that apply and capture project-specific decisions in their own context doc. Propose changes to the guideline itself via PR + ADR.

**Rails baseline:** Use the **latest stable Rails 8** release and follow current Rails conventions and methodologies (Rails guides, omakase stack, the built-in authentication generator, `params.expect`, Active Record encryption, Solid trilogy, Hotwire-first UI). Revisit `docs/UPGRADE_PLAN.md` when Ruby, Rails, or PostgreSQL approach EOL.

**Scope:** Application/technical layer only. Infrastructure (hosting, TLS termination, backups/DR, cloud cost, deployment topology, monitoring stack) is **out of scope** unless enabled via an add-on. Where a requirement has both an app and an infra half, only the app half is covered in the mandatory sections.

**Privacy:** Strict privacy-by-design controls are **mandatory** (see §11). Region- or industry-specific compliance (GDPR, PIPEDA, HIPAA, SOC 2, etc.) is **not** assumed — enable the relevant **Compliance add-on** when a project requires it.

---

## 1. How to Use This Guideline

- **The mandatory sections below apply to every project** unless an ADR documents a justified exception (§21).
- The **Add-On Catalog** is opt-in: enable only the packs a project actually needs; each enabled add-on gets an ADR and integration notes.
- **Do not edit this document per project.** Instead, each project keeps a short **project addendum** (e.g. `docs/PROJECT_CONTEXT.md`) recording the points below. The guideline stays the shared baseline; the addendum holds what varies.
- Treat this as a living standard: improvements flow back here via PR + ADR so every future project benefits.

**Project addendum template** (lives in the project repo, not here):

| Field | Value |
|-------|-------|
| **Product summary** | One paragraph: what the app does and for whom |
| **Core user loop** | e.g. sign up → onboard → primary action → outcome |
| **Roles** | List roles and whether they are fixed or mutable |
| **Stack notes** | Rails/Ruby/PostgreSQL versions; any deviation from the omakase defaults |
| **Enabled add-ons** | Which catalog packs are active (+ ADR links) |
| **Out of scope** | Explicit exclusions for this phase |
| **Open TBCs / assumptions** | Decisions pending product/legal/ops confirmation |

---

## 2. Local Setup Checklist

Before your first PR:

1. Install Ruby from `.ruby-version` and PostgreSQL.
2. `bundle install` and `bin/rails db:prepare` (prepares primary + Solid Cache / Queue / Cable databases per Rails 8 defaults).
3. Start with **`bin/dev`** (not `rails server` alone).
4. Configure secrets in `bin/rails credentials:edit` or ENV — **never in source**. Enable provider add-ons only after sandbox credentials are in place.
5. Run the quality gate with **`bin/ci`** (defined in `config/ci.rb`, the Rails 8.1 CI DSL).
6. Read open **ADRs** in `docs/adr/`.
7. Install project Cursor rules into `.cursor/rules/` so the assistant enforces this standard while you code.

---

## 3. Architecture & Where Logic Lives

Follow current Rails conventions: thin controllers, rich domain boundaries, framework features before custom infrastructure.

### Controllers — thin
HTTP only: params (prefer `params.expect`), `authorize`, delegate to a service, render/redirect. No business logic, no third-party calls, no domain calculations in controllers.

### Models — balanced
Associations, validations, scopes, `normalizes`, lightweight entity logic. No multi-step orchestration or external provider calls in models.

### Logic placement

| Pattern | Use for |
|---------|---------|
| **Service object** | Use-case orchestration: `Accounts::Register`, `Orders::Place`, `Workflows::Advance` |
| **Query object** | Filtered/sorted lists, search, reporting reads |
| **Form object** | Multi-step wizards, compound validations across models |
| **Presenter / Serializer** | Field-level output control — **the only path** for role- or stage-sensitive data |
| **Adapter** | One per external provider — **no provider SDK calls outside adapters** |
| **Policy** | Pundit (or equivalent) per resource, per role and lifecycle stage |
| **Concern** | Rarely — only truly shared behaviour (e.g. `Auditable`, `SoftDeletable`) |

### Anti-patterns (do not ship)
- Business logic or provider calls in controllers/views.
- `default_scope` on any model — use named scopes (`kept`, `published`, `active`).
- `permit!` / unfiltered mass assignment.
- Raw SQL with string interpolation.
- Skipping `authorize` on a controller action without documented `skip_authorization`.
- Relying on UI hiding for authorization or data visibility.
- Broadcasting Turbo Streams / Cable without per-user authorization.
- Passing ActiveRecord objects to jobs — **pass IDs**.
- Hardcoding business rules that product/legal may change — use **configuration**.
- Calling an external provider without timeout, retry policy, and idempotency (see §9).

---

## 4. Authentication *(mandatory baseline)*

Every project ships a **session-based authentication foundation** that can grow without rework.

### Mandatory
- **Rails 8 built-in authentication generator** (`bin/rails generate authentication`) as the baseline — server-side, revocable sessions backed by `has_secure_password` (bcrypt). This is the current Rails-native (omakase) path; prefer it over third-party auth stacks unless an add-on justifies otherwise.
- **User model** separate from the auth mechanism — provider/credential details live in an **`Identity`** (or equivalent) table, not as hardwired columns on `User`. Adding OAuth or another provider later is a **data addition**, not a refactor.
- Single entry service for sign-in/sign-up flows (e.g. `Identities::Authenticate`, `Identities::FromOmniauth`) that creates/links `User` + `Identity`.
- **CSRF protection** on all browser auth flows. If OmniAuth is added later (A1), **`omniauth-rails_csrf_protection`** is mandatory.
- Rate-limit auth endpoints with `rack-attack`.
- Expose **sign out everywhere** (revoke all sessions) when the product has account security requirements.
- Document any deviation from the built-in baseline (e.g. adopting Devise) in an ADR (§21).

```ruby
# Extensible: provider is data, not hardwired
class User < ApplicationRecord
  has_many :identities, dependent: :destroy
  # enum :role, ... — define per project
end

class Identity < ApplicationRecord
  belongs_to :user
  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
end
```

### Deferred to add-ons
- OAuth / SSO providers (Google, Apple, Microsoft, SAML)
- API tokens, JWT, machine-to-machine auth
- MFA / WebAuthn
- Magic links / passwordless email
- **Devise** or another full-featured auth toolkit, when its batteries-included flows are preferred over the built-in generator

> **Add-on:** See **A1. Authentication & SSO** in the add-on catalog.

---

## 5. Authorization

- **`authorize` on every controller action** (or `skip_authorization` with a comment explaining why).
- **Policy class per resource** — test both allowed and denied paths.
- Authorization applies equally to **HTML, Turbo Streams, JSON APIs, and Solid Cable channels**.
- Complex **data visibility** (field-level rules by role/stage) is enforced **server-side** via policies + presenters/serializers — never by hiding in the UI.

```ruby
class ApplicationCable::Channel
  # Every channel: authorize in #subscribed, reject otherwise
end
```

> **Add-on:** See **Field-level data visibility** when the domain requires staged or role-based field exposure (e.g. marketplaces, hiring, healthcare).

---

## 6. Real-Time (Solid Cable)

- Use **Solid Cable** (Rails 8 default) for server-pushed updates.
- **Every channel authorizes the subscriber in `#subscribed` and `reject`s otherwise.** Never infer a private stream from a client-supplied id alone.
- Prefer **Turbo Streams over raw Cable** for view updates; use channels when broadcast semantics genuinely need them.
- Broadcasts carry **IDs and rendered partials** — presenters/serializers still govern sensitive output.

```ruby
class ExampleChannel < ApplicationCable::Channel
  def subscribed
    record = ExampleRecord.find(params[:id])
    reject unless policy(record).show?
    stream_for record
  end
end
```

---

## 7. Background Jobs & Scheduling (Solid Queue)

- Use **Solid Queue** (Rails 8 default) with separate queue database.
- Serialize **IDs, not records**; pass `user_id` and `request_id` for audit context where needed.
- Jobs touching external systems or money must be **idempotent** (safe to run twice).
- Set explicit **retry limits** and queue priorities (e.g. `critical`, `default`, `low`).
- **Long-running / multi-step jobs** use **`ActiveJob::Continuable`** (Rails 8.1) so work resumes from the last completed step after a restart or deploy instead of re-running from the beginning.
- Mailers: **`deliver_later`** — never block the request thread on outbound email.
- Recurring work: `config/recurring.yml` (Solid Queue recurring tasks).
- Reset **`Current`** per request; set context explicitly inside jobs.

---

## 8. Caching (Solid Cache)

- Use **Solid Cache** (Rails 8 default) with separate cache database.
- Fragment/collection caching with **defined TTLs** and explicit cache keys.
- Invalidate on domain events — do not rely on unbounded forever caches for user-specific data.

---

## 9. Third-Party Integration Resilience *(mandatory when any add-on provider is enabled)*

Whenever the app calls an external API (payments, email, storage, identity, maps, etc.), these patterns are **mandatory for every adapter**.

### Timeouts
Every outbound call sets explicit **connect + read timeouts**. No unbounded waits.

### Error classification

| Class | Examples | Action |
|-------|----------|--------|
| **Transient** | timeout, connection reset, HTTP 408/5xx | Retry with backoff |
| **Rate-limited** | HTTP 429 | Honour `Retry-After`; back off; throttle |
| **Permanent** | HTTP 400/422 validation, 401/403 auth | **Do not retry** — surface error, alert, or route to manual handling |

### Retry with backoff + jitter
- Bounded max attempts (e.g. 5), **exponential backoff + jitter**, transient/rate-limited only.
- Retries at the **job layer**, keyed by **idempotency keys** — a retried call must not double-charge or double-submit.

### Circuit breaker (per provider)
- After N consecutive failures, **fail fast** for a cooldown; **half-open** probe before closing.

### Outbound throttling
- Respect provider rate limits; avoid burst fan-out against shared or limited APIs.

### Idempotency
- User-initiated mutations that must not duplicate (payments, workflow starts, invitations) carry **idempotency tokens**.
- Webhooks: **dedupe on provider event id**; tolerate duplicate and out-of-order delivery.

### Dead-letter + alert
- When retries exhaust, move to dead-letter state and **alert**. Domain-specific recovery (e.g. manual review) belongs in the relevant add-on.

### Reconciliation (sweep)
- A recurring job detects **stuck/orphaned** states (webhook never arrived, job stuck `running`) and drives resolution.

### User-facing state
- Users see clear status — never a raw error or dead end. Tie to Turbo error-handling (§13).

### Telemetry
- Log attempt count, outcome, and latency. **Keep provider PII out of logs** (§11).

```ruby
class Example::Client
  def call(context)
    Circuit.for(:example).run do
      resp = http.post(...)  # connect/read timeouts set
      classify!(resp)        # raise Retryable / Permanent
    end
  end
end
```

> **Add-on:** Provider-specific adapters (Stripe, SendGrid, S3, etc.) live in the add-on catalog.

---

## 10. Security Rules

- **CSRF** enabled everywhere on browser forms — never skipped without ADR.
- **CSP** configured for importmap/Stimulus (nonces in production).
- **Security headers:** CSP, `X-Content-Type-Options`, frame protection, Referrer-Policy, Permissions-Policy. (HSTS at load balancer — infra.)
- **Secrets** only in Rails credentials / ENV — never in source. Scan git history before first deploy.
- **Rate-limit** sensitive endpoints: auth, payment initiation, expensive mutations (`rack-attack`).
- **Abuse protection:** per-actor limits and anomaly monitoring for high-value reads/writes where scraping or bulk abuse is a threat.
- **Validate file uploads:** type, size, content sniffing; store privately; scan before processing when uploads are in scope.
- **Sanitize** user-rendered HTML — default to plain text unless rich text is an explicit requirement.
- **Account deletion** implemented as service objects with verifiable cascade rules (retention windows are project-configured).

Run before every merge:

```bash
bundle exec brakeman -q -w2
bundle audit check --update
```

---

## 11. Privacy Requirements *(mandatory — strict, regulation-agnostic)*

These apply to **every** project. Enable a **Compliance add-on** when a specific regulation maps controls to legal obligations.

### Data minimization
- Collect only fields required for the product. Document why each sensitive field exists.
- Do not store credentials, government IDs, or financial identifiers unless an add-on explicitly requires them and legal approves.

### Consent (when collecting personal or sensitive data)
- Capture **purpose, scope, timestamp, and policy version** before processing that requires consent.
- Downstream jobs refuse to run without valid consent when consent-gated.

### Access logging
- **Append-only audit log** for critical data **writes** (who, what, old/new).
- **Reads of sensitive personal data** are logged at presenter/serializer boundaries when those fields exist: actor, subject, fields/purpose, timestamp.

### Encryption
- Sensitive PII **at rest** via Active Record Encryption (or equivalent) when stored.
- In-transit TLS is infrastructure-owned but must be enforced in every environment.

### Data retention & deletion
- Define retention windows in **configuration** — not magic numbers in code.
- Scheduled auto-purge for expired artifacts.
- Account deletion triggers **verifiable erase** across primary and derived stores.

### Log filtering
- Filter passwords, tokens, session ids, email, phone, and domain-sensitive fields from logs (`config.filter_parameters` + adapter discipline).

### Admin / operator access
- Prefer **masked-by-default** views for sensitive data.
- Standing raw-PII access for operators is discouraged; if required, use **audited, reason-tagged, time-boxed** access with logging.

> **Add-on:** See **Compliance packs** (GDPR, PIPEDA, HIPAA, SOC 2, etc.) when legal assigns formal obligations.

---

## 12. Database Rules

- Enforce integrity in **migrations**: NOT NULL, foreign keys, unique indexes, check constraints.
- Index every FK and hot `WHERE` / `ORDER BY` column.
- Always `.order()` + paginate (`pagy`) — **no unbounded queries**.
- **Soft delete** (when used): `deleted_at` + `deleted_by_id`, `kept` scope, **partial unique indexes**.
- **Public URLs use UUID/nanoid, not sequential IDs** when enumeration or count leakage is a concern.
- Money: **integer cents**, never floats.
- Times: store UTC, display in user timezone (configure default per project).
- `lock_version` on concurrently edited records.
- No `default_scope`.

---

## 13. Frontend & Accessibility

- **Hotwire first** — Turbo Drive, Frames, Streams before custom JS; Stimulus for behaviour.
- Disable submit on `turbo:submit-start`; handle `turbo:fetch-request-error` with retry UI (graceful degradation, ties to §9 user-facing state).
- **Accessibility target: WCAG 2.1 AA** (mandatory, regardless of target device): semantic HTML, programmatic labels, visible focus states, ≥ 4.5:1 text contrast, keyboard operability, and correct ARIA only where native semantics fall short. Run `axe-core` in system tests on key flows and fix AA violations before merge.
- Use responsive units sensibly (`h-dvh` over `h-screen`) so layouts don't break on small viewports, even when mobile is not a primary target.

> **Add-on:** See **A18. Mobile & Responsive UX** when the product must be first-class on phones (touch targets, iOS input handling, table→card layouts, mobile system tests).

---

## 14. Performance

- Index coverage on filter/sort columns; `EXPLAIN` complex queries before merge.
- **N+1:** `bullet` in dev/test — **zero warnings before merge**; use `includes`/`preload`.
- **Solid Cache** for fragment/collection caching with TTLs.
- **Profiling (dev):** `rack-mini-profiler` + `derailed_benchmarks` before shipping heavy actions.
- No unbounded queries; always paginate.

---

## 15. Testing Requirements

| Type | Requirement |
|------|-------------|
| **Model / service** | Core domain logic, edge cases, idempotency |
| **Policy** | Every action × authorized **and** denied actors |
| **Request** | Every controller action; Turbo Stream format where used |
| **Channel** | Subscriber authorization — allowed subscribes, others rejected |
| **Integration (providers)** | Adapters against recorded/stubbed responses (VCR/WebMock) when add-ons enabled |
| **Resilience** | Transient → retry; permanent → no retry; reconciliation rescues stuck states |
| **System** | Primary user loop end-to-end (add a mobile viewport, e.g. 390×844, when A18 is enabled) |
| **Coverage** | ≥ 80% line coverage (SimpleCov in CI) |

Add **regression suites** for each enabled add-on (data visibility, payments, compliance logging, etc.).

---

## 16. Code Quality Gates (Local & CI)

These must pass before merge:

| Check | Command / tool |
|-------|----------------|
| RuboCop | `bundle exec rubocop` (`rubocop-rails`) |
| Brakeman | `bundle exec brakeman -q -w2` |
| CVE scan | `bundle audit check --update` |
| Tests + coverage | `COVERAGE=true bundle exec rspec` (≥ 80%) |
| N+1 | Bullet — zero warnings before merge |
| Complexity trend | Track duplication/complexity per release; no critical smell unresolved beyond one sprint |

Define these gates in **`config/ci.rb`** and run them with **`bin/ci`** (the Rails 8.1 CI DSL) both locally and in the pipeline, so local and CI gates stay identical.

---

## 17. Technical Debt Management

Codebases accrue debt fastest when shortcuts go untracked; budget for paydown from day one so the code stays changeable. These are **mandatory practices**, not aspirations.

### Track it explicitly
- Every deliberate shortcut, `TODO`, `FIXME`, or `rubocop:disable` carries a **ticket reference** and a short reason — no orphan markers.
- Maintain a lightweight **debt register** (issue label or `docs/TECH_DEBT.md`) so deferred work is visible, not lost in code comments.
- Capture deferred or uncertain decisions as **ADRs with a "revisit by" trigger** (date or milestone), including a register of open **TBC/assumption items** carried into the build.

### Keep dependencies current
- Treat **Ruby / Rails / PostgreSQL upgrades** as recurring work in `docs/UPGRADE_PLAN.md`; review on each EOL cycle, not when forced.
- Resolve **deprecation warnings** before the framework removes them — run with deprecation logging in CI and don't let warnings accumulate.
- Keep dependencies patched: `bundle audit` (CVE) and routine `bundle outdated` review; no unsupported/abandoned gems without an ADR and exit plan.

### Bound complexity & duplication
- Track **complexity and duplication trend** per release (RuboCop metrics cops, or a SonarQube/CodeClimate report); **no critical smell unresolved beyond one sprint** (ties to §16).
- Delete dead code, unused gems, and feature-flagged remnants promptly — don't comment out, remove (git is the history).
- Refactor opportunistically alongside feature work; reserve a small **refactoring budget** each cycle for paydown.

### Schema & data debt
- Use safe/strong migration practices (no blocking changes on large tables; add indexes concurrently where supported).
- Retire stale columns, indexes, and tables; back deprecations with a migration plan, not indefinite "we'll clean it later."

### Test & quality debt
- **Quarantine flaky tests** with a ticket and a deadline — never silently `skip` or retry away failures.
- Protect the coverage floor (§16); treat unexplained coverage drops as debt to address in the same PR.
- Backlog and burn down **N+1 / performance warnings** rather than permanently silencing Bullet.

### Documentation drift
- Update README, ADRs, and `docs/integrations/` in the **same PR** as the change — stale docs are debt that compounds.

---

## 18. Environment & Configuration

- **Environment parity:** `development`, `test`, `staging`, `production`. **Staging mirrors production** configuration (same Solid trilogy setup, same job/cache behaviour) so issues surface before release. Avoid env-conditional business logic — branch on **configuration**, not `Rails.env`, in app code.
- **Config sources:** Rails **credentials** (per-environment encrypted credentials) and **ENV** only — never secrets in source. Follow 12-factor for anything that varies by environment.
- **Document required configuration:** maintain a checked-in `.env.example` (or a config section in the README) listing every required ENV var and credential key, with safe placeholder values.
- **Typed config:** read settings via `Rails.application.config_for(:name)` / `config/*.yml` rather than scattering `ENV[...]` reads through the codebase.
- **Third-party credentials:** non-production environments use **sandbox/test keys**; production keys never leave production credentials.
- **Seed data:** `db/seeds.rb` is **idempotent and safe to re-run**. Keep required reference seeds separate from demo/sample data (e.g. `db/seeds/` + a `demo` task). **Never seed real PII.**
- **Defaults:** set application time zone and default locale in `config/application.rb`; store times in UTC (§12).

---

## 19. Error Handling & API Contract

- **Custom error pages** for 404 / 422 / 500 — branded, helpful, and **never expose stack traces or internals** in production.
- **Controlled rescue hierarchy:** rescue known domain errors and map them to user-facing messages/status; let truly unexpected errors hit the error tracker (A10). No bare `rescue` that swallows failures.
- **Turbo:** handle `turbo:fetch-request-error` with retry UI; keep the user in a clear state, never a dead end (ties to §9 and §13).
- **Request correlation:** every request carries a request id (`X-Request-Id`, accepted or generated at the edge), surfaced in logs and propagated into jobs and outbound calls (§20).
- **Structured error bodies** for any JSON/webhook endpoint, even before the full API add-on: stable shape and correct HTTP status, e.g.

```json
{ "error": { "code": "validation_failed", "message": "Human-readable summary", "details": {} } }
```

- **Jobs:** failures are reported to error tracking and follow §9 retry/dead-letter rules — never silently discarded.

> **Add-on:** Full versioned API surface, pagination, and serialization conventions live in **A13. API Layer**.

---

## 20. Observability & Logging

Baseline observability is **mandatory**; richer tooling (APM, dashboards) is opt-in via **A10**.

- **Structured logging** (JSON or `key=value`, e.g. lograge-style) including request id, current user id, controller/action, status, and duration. Avoid noisy multi-line default logs in production.
- **Structured events** use the Rails 8.1 **Event Reporter** (`Rails.event.notify("name", **payload)`, with `Rails.event.tagged` / `set_context` for request context) emitted to registered subscribers, rather than ad-hoc log lines — giving events a consistent, post-processable shape.
- **Correlation id** generated/accepted at the edge, stored in **`Current`**, and propagated into **Solid Queue jobs** and **outbound provider calls** so one request is traceable end-to-end.
- **Log filtering is mandatory:** passwords, tokens, session ids, and sensitive PII are filtered (`config.filter_parameters`); provider PII stays out of integration logs (ties to §11 and §9 telemetry).
- **Health check:** expose Rails 8's `/up` (or equivalent) for uptime/load-balancer probes.
- **Operational signals:** at minimum, record request latency, job outcomes, and provider-call telemetry (§9) so the app is debuggable without a full APM stack.

> **Add-on:** Error tracking, APM, and centralized log aggregation live in **A10. Observability & Alerting**.

---

## 21. Governance, Versioning & Exceptions

- **Ownership:** this guideline is owned by `[Engineering leadership / architecture group]`, who review and approve changes.
- **Change process:** propose edits via **PR + ADR**; material changes are communicated to all active teams. Improvements discovered on a project flow back here rather than living only in that project.
- **Versioning:** the guideline carries a version and a dated **Changelog** (end of document). Projects record **which guideline version they adopted** in their addendum (§1).
- **Exceptions:** any deviation from a **mandatory** rule requires an **ADR** stating the rule, the reason, the scope, and a **revisit trigger** (date or milestone). Exceptions are **time-boxed and reviewed** — not permanent.
- **Add-ons:** enabling or removing an add-on is itself an ADR-worthy decision recorded in the project addendum.

---

## 22. Audit & Domain Events

- **Append-only audit log** for critical mutations.
- Extend with **PII read logging** when the domain stores sensitive personal data (§11).
- Use **`Current`** for actor/request context; reset after each request; set in jobs.
- Model lifecycle changes as **domain events** (emitted via the Event Reporter, §20), not fat callbacks; handlers run async via Solid Queue and are idempotent.

---

## 23. Core Gems *(mandatory minimum)*

Stay minimal. Pre-approved core:

| Gem | Purpose |
|-----|---------|
| `bcrypt` | Password hashing for the built-in auth generator (`has_secure_password`) |
| `pundit` | Authorization |
| `rack-attack` | Rate limiting |
| `pagy` | Pagination |
| `bullet` | N+1 detection (dev/test) |
| `brakeman`, `bundler-audit` | Security scanning |
| `rubocop-rails` | Linting |
| `simplecov` | Coverage (test) |
| `rack-mini-profiler`, `derailed_benchmarks` | Perf profiling (dev) |
| `vcr`, `webmock` | Provider tests (test, when add-ons enabled) |

**HTTP client + resilience** (required when any provider add-on is enabled): an HTTP client with explicit timeouts (e.g. `faraday`); a circuit-breaker gem (e.g. `stoplight`).

Any gem outside core + enabled add-ons needs an **ADR** with justification.

> **Add-on:** See catalog for provider gems, observability, feature flags, etc.

---

## 24. Documentation You Must Maintain

| Artifact | When to update |
|----------|----------------|
| **README** | Setup steps change |
| **ADR** (`docs/adr/`) | Any hard-to-reverse decision |
| **`docs/UPGRADE_PLAN.md`** | Ruby/Rails/PostgreSQL EOL review |
| **`docs/integrations/`** | Per enabled provider add-on |
| **`docs/PROJECT_CONTEXT.md`** (addendum) | Product context, roles, enabled add-ons, adopted guideline version (§1) |
| **`.env.example`** | Required ENV vars / credential keys change (§18) |
| **Compliance appendix** | When a compliance add-on is enabled and controls change |

---

## 25. Quick Reference Card

```
✓ Rails 8 + Solid Cache / Queue / Cable · Hotwire-first · latest Rails conventions
✓ Thin controllers · Service objects for orchestration · Adapters for providers
✓ authorize every action · Policy specs (allow + deny)
✓ Built-in auth generator (sessions) · Identity model · OAuth/SSO/Devise via add-ons
✓ params.expect · normalizes + DB constraints · no default_scope · kept scope
✓ UUID public ids · money in cents · UTC times · lock_version
✓ Provider calls: timeout · classify · backoff+jitter · circuit breaker · idempotency · reconcile
✓ Jobs idempotent · IDs not objects · ActiveJob::Continuable for long jobs · deliver_later for mailers
✓ Authorize every Cable channel · Turbo before custom JS
✓ Privacy: minimize · encrypt sensitive PII · audit writes (+ reads when applicable) · retention config
✓ Hotwire-first · WCAG 2.1 AA + axe-core on key flows (mobile UX via A18)
✓ Env parity (staging ≈ prod) · config/credentials not Rails.env branching · idempotent seeds · no real PII in seeds
✓ Branded error pages · structured JSON errors · no stack traces in prod
✓ Structured logs + Event Reporter · request correlation id (Current → jobs → providers) · /up health check · filtered params
✓ Guideline is versioned · exceptions need a time-boxed ADR · improvements flow back upstream
✓ bin/ci gates: Brakeman + bundler-audit + RuboCop + RSpec + Bullet before merge · ≥80% coverage
✓ Tech debt tracked (ticketed TODOs · debt register · ADR revisit triggers) · deps/EOL current · flaky tests quarantined
✗ No secrets in code · No permit! · No SQL interpolation
✗ No untimed/un-retried provider calls · No UI-only authorization
```

---

# Add-On Catalog

Enable only what the project needs. Each add-on should have an ADR, integration notes under `docs/integrations/`, and targeted tests. All provider add-ons **must** implement §9 resilience patterns.

---

## A1. Authentication & SSO

| Pack | Includes |
|------|----------|
| **OAuth — Google** | `omniauth-google-oauth2`, `omniauth-rails_csrf_protection`, `Identities::FromOmniauth` |
| **OAuth — Apple** | `omniauth-apple`, Sign in with Apple setup |
| **SAML / enterprise SSO** | SAML provider gem, org domain routing |
| **API tokens** | Token model, rotation, scoped abilities |
| **MFA / WebAuthn** | TOTP or WebAuthn second factor |
| **Magic links / passwordless** | Signed, expiring email links |
| **Devise (full auth toolkit)** | Alternative to the built-in generator when richer flows (confirmable, lockable, recoverable, etc.) are needed — *replaces* the §4 baseline; record in an ADR |

Baseline email/password sessions are already provided by the §4 built-in generator; these packs extend or replace it.

---

## A2. Payments

| Pack | Includes |
|------|----------|
| **Stripe — one-time charges** | `stripe` gem, `Payments::Charge` service, integer cents, idempotency keys |
| **Stripe — subscriptions** | Webhooks, proration, customer portal |
| **Stripe — Connect / marketplace** | Split payments, connected accounts |
| **Refunds & disputes** | Webhook handlers, audit trail |

**Mandatory when enabled:** charge ordering in services; webhook signature verification; idempotent webhook handlers; no floats for money.

---

## A3. Identity & Verification (KYC / background)

| Pack | Includes |
|------|----------|
| **Identity verification** | Provider adapter, async job pipeline, consent gating |
| **Credit / background check** | Adapter, result normalization, manual review path |
| **Document upload fallback** | Active Storage private bucket, virus scan hook, operator review queue |

**Patterns:** async fan-out → converge; per-step state machine; `manual_review` recovery instead of silent failure when automation cannot complete; long pipelines use **`ActiveJob::Continuable`** so a restart resumes mid-pipeline rather than re-running completed steps.

---

## A4. Financial Data (bank linking / income)

| Pack | Includes |
|------|----------|
| **Bank linking** | e.g. Plaid adapter, link token flow, webhook/poll convergence |
| **Income verification** | Normalized bands — never expose raw account numbers to unauthorized roles |

---

## A5. Geolocation & Places

| Pack | Includes |
|------|----------|
| **Address autocomplete** | Places adapter, region bias, stored normalized address components |
| **Geo search / regions** | Spatial queries, region assignment |

---

## A6. Messaging & Notifications

| Pack | Includes |
|------|----------|
| **In-app messaging** | Thread model, Solid Cable channels, participant authorization |
| **Transactional email** | Provider adapter (Postmark, SendGrid, etc.), template versioning |
| **Push notifications** | Device tokens, silent/data pushes |
| **SMS** | Twilio or equivalent, opt-in logging |

---

## A7. Search, Matching & Ranking

| Pack | Includes |
|------|----------|
| **Full-text search** | pg_search, OpenSearch, etc. |
| **Matching engine** | `CandidateQuery` + `Rank` services, indexed filters |
| **Configurable scoring** | Weights in `config/scoring.yml` or versioned DB settings — never hardcoded |
| **Real-time match refresh** | Solid Queue refresh on domain events + Turbo/Cable nudges |

**Explainability & fairness (mandatory when scoring or ranking affects people):** a score must be **reproducible** from its stored inputs plus the active, **versioned** weight set; a **missing input is scored neutrally**, never penalised as negative; and **no protected-ground attribute** (or close proxy) may influence the result. Add regression tests asserting reproducibility, neutral-absence handling, and non-influence of protected attributes.

---

## A8. Field-Level Data Visibility

Use when unauthorized roles must never receive certain fields, or field exposure depends on workflow stage.

| Mechanism | Responsibility |
|-----------|----------------|
| **Policy** | Whether the actor may access the resource at this stage |
| **Presenter / Serializer** | *Which fields* are emitted — sole render path for sensitive views |
| **Scopes** | Lifecycle gating — ineligible records never enter queries |
| **Encryption** | Sensitive columns at rest |

Include **data-visibility regression tests** that assert forbidden fields are unreachable in every presenter/API path.

---

## A9. File Storage & Media

| Pack | Includes |
|------|----------|
| **Active Storage — S3** | Private buckets, direct upload, variants via `image_processing` |
| **CDN delivery** | Signed URLs for non-public assets |

---

## A10. Observability & Alerting

| Pack | Includes |
|------|----------|
| **Error tracking** | Sentry, Honeybadger, or similar + dead-letter alerts |
| **APM** | Skylight, Datadog, etc. |
| **Structured logging** | JSON logs, correlation ids |

---

## A11. Feature Flags & Experimentation

| Pack | Includes |
|------|----------|
| **Feature flags** | Flipper or similar, audited toggles |
| **A/B testing** | Experiment assignment + reporting hooks |

---

## A12. Multi-Tenancy

| Pack | Includes |
|------|----------|
| **Row-level tenancy** | `account_id` scoping, policy default scope |
| **Subdomain / domain routing** | Tenant resolution middleware |

---

## A13. API Layer

| Pack | Includes |
|------|----------|
| **JSON API** | Versioned controllers, serializers, rate limits |
| **GraphQL** | Schema, N+1 control, complexity limits |
| **Webhooks (outbound)** | Signed deliveries, retries, idempotency |

---

## A14. Internationalization

| Pack | Includes |
|------|----------|
| **i18n** | Rails I18n, locale routing, translated copy workflow |
| **RTL / locale-specific formats** | Additional QA matrix |

---

## A15. Compliance Packs *(enable per legal requirement)*

These extend §11 with regulation-specific controls. **Do not enable unless legal assigns obligations.**

| Pack | Typical technical additions |
|------|----------------------------|
| **GDPR** | Lawful basis tracking, DSR export/delete SLAs, DPA subprocessors doc |
| **PIPEDA / Canadian privacy** | Consent records per purpose, access logging, data residency notes |
| **HIPAA** | BAA subprocessors, audit immutability, minimum necessary enforcement |
| **SOC 2** | Change management evidence, access reviews, encryption attestations |
| **PCI** | No raw card data on servers, SAQ scope reduction via hosted fields |

Each pack should add a **compliance appendix** referenced from the main doc.

---

## A16. Deployment & Infrastructure *(application-facing only)*

Infrastructure topology varies by project. Document the chosen approach in `docs/deployment/` and an ADR.

| Pack | Notes |
|------|-------|
| **Kamal** | `config/deploy.yml`, accessory services, secrets, zero-downtime deploy hooks |
| **Docker / Compose** | Local parity, production image |
| **PaaS** | Heroku, Render, Fly.io — buildpack/Dockerfile conventions |
| **Kubernetes / ECS** | Helm/charts, health checks, job workers as separate processes |
| **CI/CD** | GitHub Actions, quality gates, staged deploys |

**Out of mandatory guideline:** specific hostnames, TLS termination, backups/DR, cost optimization — owned by ops unless this add-on is activated for the team.

---

## A17. Admin & Operations

| Pack | Includes |
|------|----------|
| **Admin dashboard** | Read-only health counters, masked PII by default |
| **Operator queues** | Manual review, JIT unmask with audit |
| **Impersonation** | Audited, time-boxed user impersonation for support |

---

## A18. Mobile & Responsive UX

Enable when the product must be first-class on phones/tablets. Accessibility (§13) stays mandatory regardless.

| Concern | Includes |
|---------|----------|
| **Mobile-first layout** | Mobile-first CSS (Tailwind recommended), `h-dvh` over `h-screen`, breakpoint strategy |
| **Touch ergonomics** | Touch targets ≥ 44×44px; `active:` / `focus-visible:` states, not hover-only |
| **Mobile forms** | 16px inputs on iOS (avoid zoom), correct `inputmode`, sticky submit on long/multi-step forms |
| **Responsive patterns** | Tables → cards below `md`; navigation and modals adapted for small screens |
| **Mobile system tests** | Core loop verified at a mobile viewport (e.g. 390×844) |
| **Performance on device** | Budget payload/JS for mobile networks; verify interactive speed on mid-tier devices |

---

# Appendix — Per-Project Adoption Checklist

When starting a new project that adopts this guideline (do this in the project repo, not in this document):

- [ ] Create the project addendum (`docs/PROJECT_CONTEXT.md`) using the §1 template
- [ ] Confirm Ruby/Rails/PostgreSQL versions in `.ruby-version` / `Gemfile`
- [ ] Decide and record enabled add-ons from the catalog; add an ADR per add-on
- [ ] Create `docs/integrations/<provider>.md` for each provider add-on
- [ ] Add a compliance appendix if a compliance pack (A15) is enabled
- [ ] Add a deployment doc if A16 is enabled
- [ ] Enable A18 (Mobile & Responsive UX) if phones/tablets are a primary target
- [ ] Define `config/ci.rb` (run via `bin/ci`) with the §16 gates
- [ ] Stand up the tech-debt register (`docs/TECH_DEBT.md` or issue label) and `docs/UPGRADE_PLAN.md` (§17)
- [ ] Add Cursor rules reflecting the mandatory standard + enabled add-ons
- [ ] Link the project addendum back to this guideline (reference, don't copy)

---

# Changelog

| Version | Date | Changes |
|---------|------|---------|
| **1.4** | 2026-06-23 | Switched the auth baseline to the **Rails 8 built-in authentication generator** (Devise moved to A1 as an alternative; `bcrypt` replaces `devise` in core gems; password auth is now baseline, not deferred). Adopted Rails 8.1 conventions: **Event Reporter** (§20, §22), **`ActiveJob::Continuable`** (§7, A3), and **`config/ci.rb` + `bin/ci`** (§2, §16, checklist). Added scoring **explainability & fairness** controls (A7). Consistency: generalized "greenfield" wording in mandatory sections (§11, §17), mandatory-scope phrasing (§1), and "e.g." gem phrasing (§23). |
| **1.3** | 2026-06-23 | Added Governance/Versioning/Exceptions (§21), Environment & Configuration (§18), Error Handling & API Contract (§19), Observability & Logging (§20); set explicit **WCAG 2.1 AA** target (§13). Renumbered Audit/Core Gems/Documentation/Quick Reference accordingly. |
| **1.2** | 2026-06-23 | Reframed from a per-project template into a project-agnostic standing standard; replaced "Project Context" with "How to Use This Guideline" + project-addendum model. |
| **1.1** | 2026-06-23 | Moved mobile-specific UX into add-on **A18**; added **Technical Debt Management** (§17). |
| **1.0** | 2026-06-23 | Initial generic Rails 8 baseline extracted from production standards. |

*Guideline version: 1.4 — Rails 8 engineering standard (project-agnostic)*
