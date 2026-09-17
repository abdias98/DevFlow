# Review Checklist

This checklist guides the Reviewer in both Cycle Mode and Standalone Mode. Apply the relevant sections based on the feature type (UI, API, backend, etc.) and the standards loaded.

## Section Ownership

Each check section belongs to exactly one review subagent (`SKILL.md` → Step 3). On the inline path the Reviewer applies all of them itself.

| Section | Subagent |
|---------|----------|
| Security (OWASP Top 10) | 1 — Security & Safety |
| Error Handling | 1 — Security & Safety |
| Performance | 2 — Performance, Concurrency & Data |
| Concurrency | 2 — Performance, Concurrency & Data |
| State & Data Lifecycle | 2 — Performance, Concurrency & Data |
| Data Persistence | 2 — Performance, Concurrency & Data |
| Code Quality | 3 — Architecture & Design |
| Architecture Alignment | 3 — Architecture & Design |
| Test Coverage | 3 — Architecture & Design |
| Correctness & Behavior | 4 — Correctness & Behavior |
| API-Specific Checks | 5a — Interfaces |
| Event-Driven Checks | 5a — Interfaces |
| Integration Consumption Checks | 5a — Interfaces |
| Design Patterns Checks | 5d — Structural Patterns |
| UI-Specific Checks | 5b — Presentation |
| Accessibility | 5b — Presentation |
| Logging | 5c — Operations |
| Dependencies | 5c — Operations |

## How to Read This Checklist

**This checklist declares no severities.** Each item names its source; the severity of a finding comes from that source, never from this file:

- `{standard}.md §{N}` → that standard's **Severity Classification** table.
- `rules.md` → Behavioral Impact Severity, for scenario-backed findings (the Correctness & Behavior section, and any item whose failure is an observable wrong behavior).
- *(plan)* → the item is verified against the spec/plan; a deviation is reported with the spec/plan section as the source of the expected behavior, and classified by the standard it breaks or by Behavioral Impact Severity.

When a source's severity table has no trigger for a finding, the finding takes the lowest severity that honestly describes it — never a severity invented here. A rule that should be stricter is changed **in its standard** (`standards-dry-policy.md`).

## Universal Checks (All Reviews)

### Code Quality
- [ ] Naming and structure follow the conventions already used in the codebase (`project-design.md §1`).
- [ ] No dead, commented-out or speculative code (`design-principles.md §2`).
- [ ] Each function, class or component has a single reason to change (`solid.md §1`); rendering, business rules and data access are not folded into one unit (`design-principles.md §3`).
- [ ] No duplicated business rule, validation or calculation (`design-principles.md §1`).
- [ ] No more machinery than the problem requires (`design-principles.md §5`).

### Security (OWASP Top 10)
- [ ] External input is validated at the boundary (`security.md §1`).
- [ ] No injection vectors — parameterized queries, output encoding (`security.md §4`).
- [ ] Authentication and authorization are enforced wherever private data is exposed or mutated (`security.md §2`).
- [ ] No hardcoded secrets or credentials (`security.md §3`).
- [ ] No sensitive data or internal detail in error responses (`security.md §6`).

### Architecture Alignment
- [ ] Implementation matches the spec/plan design and data flow *(plan)*.
- [ ] New code follows the conventions of the plan's reference implementation (or the closest sibling of the same kind) — structure, naming, error handling, state/data-loading organization, test style — or the divergence is recorded (`project-design.md §1`). A defect copied from the reference is a Correctness & Behavior finding, not a reason to diverge silently.
- [ ] No components beyond the spec/plan — scope creep (`rules.md` → Scope-Locking) *(plan)*.
- [ ] Dependencies point inward; domain code does not import infrastructure (`clean-architecture.md §1`).
- [ ] No business logic in controllers, routes, UI components or the entry point (`project-design.md §3`).

### Performance
- [ ] No query inside a loop over unbounded input (N+1) and no unbounded collection returned (`performance.md §2`).
- [ ] No unnecessary data access or blocking operation on a request/render path (`performance.md §2`, `performance.md §4`).
- [ ] Caching, memoization or lazy loading the plan requires is present, with an invalidation strategy (`performance.md §3`) *(plan)*.

### Test Coverage
*Test design and presence. Whether the tests would actually catch a defect is judged under Correctness & Behavior.*
- [ ] Every task has tests covering its happy path, an edge case and a failure scenario (`testing.md §4`).
- [ ] Edge cases named in the spec/plan are covered (`testing.md §4`) *(plan)*.
- [ ] A bug fix has a regression test that failed before the fix (`testing.md §5`).
- [ ] Tests follow Arrange/Act/Assert, mock at port boundaries and are independent (`testing.md §2`, `testing.md §3`, `testing.md §6`).

### Correctness & Behavior
Performed by subagent 4 following [correctness-guide.md](./correctness-guide.md) — blind pass (no spec/plan), then contrast pass. Findings are scenario-backed and classified with `rules.md` → Behavioral Impact Severity.
- [ ] Every changed unit's inputs, state, side effects, outputs and **consumers** were inventoried — consumers read, not assumed.
- [ ] Logic: conditions, boundaries, unhandled cases, masking defaults.
- [ ] State transitions: behavior under changed input/context with work in flight, repetition, reordering; derived state reset or recomputed when its source changes.
- [ ] Side effects: performed exactly as many times as intended; no work whose result nothing consumes; everything started is released.
- [ ] Contract with consumers: shape, nullability, ordering, error type and timing each consumer relies on still hold.
- [ ] Data limits and partial failure: what the inputs can actually produce, and what is left behind when a step fails halfway.
- [ ] Test adequacy: no plausible single mutation on a behavior-relevant path survives every test (`testing.md §4`).
- [ ] Each finding classified as implementation defect, plan gap or deliberate decision; untraceable suspicions listed as Open Questions, not findings.

### Error Handling
- [ ] No empty catch block or catch-and-continue that discards the error (`error-handling.md §2`).
- [ ] Caught errors are narrowly typed and the original cause is chained when wrapped/translated (`error-handling.md §3`).
- [ ] Errors are translated at layer boundaries (`error-handling.md §4`).
- [ ] No raw stack trace, exception message or internal detail returned to an external caller (`error-handling.md §5`).
- [ ] Resources are released and multi-step state changes are atomic on every failure path (`error-handling.md §6`).

### State & Data Lifecycle *(apply only if state that outlives a single call is present)*
- [ ] Every piece of state has exactly one write path — no second independent writer (`state-lifecycle.md §1`).
- [ ] Async updates to state discard a result superseded by a newer request for the same state (`state-lifecycle.md §6`).
- [ ] Context-scoped state resets on a context change before the new context's data arrives (`state-lifecycle.md §4`).
- [ ] Every subscription, timer or listener a piece of state opens has a matching teardown (`state-lifecycle.md §5`).
- [ ] Cache/memoization keys include every parameter the cached value depends on (`state-lifecycle.md §8`).

### Data Persistence *(apply only if a persisted schema or migration is touched)*
- [ ] Known invariants are enforced at the schema level where supported, not only in application code (`data-persistence.md §1`).
- [ ] Any new migration has a rollback path, and a breaking change is sequenced across deploys (`data-persistence.md §2`).
- [ ] A multi-step write that must be atomic is wrapped in a transaction or equivalent (`data-persistence.md §3`).
- [ ] A new query pattern has a supporting index (`data-persistence.md §5`).
- [ ] Multi-tenant queries and writes are scoped by tenant (`data-persistence.md §7`).

### Concurrency *(apply only if concurrent/async code is present)*
- [ ] No non-atomic check-then-act / read-modify-write on shared state (`concurrency.md §2`).
- [ ] No fire-and-forget async task whose failure means data loss (`concurrency.md §4`).
- [ ] Locks are held for the shortest critical section and always released (`concurrency.md §3`).
- [ ] Operations that may be retried or redelivered are idempotent (`concurrency.md §5`).

### Logging *(apply only if the change emits logs/traces/metrics)*
- [ ] No secret, credential, token or PII written to a log at any level (`logging.md §3`).
- [ ] No exception caught and silently swallowed — neither logged nor rethrown (`logging.md §6`).
- [ ] Logs are structured (named fields), not string-concatenated messages (`logging.md §1`).

### Dependencies *(apply only if manifests/lockfiles changed)*
- [ ] No known critical/high vulnerability introduced without a documented mitigation (`dependencies.md §3`).
- [ ] Lockfile is committed and consistent with the manifest (`dependencies.md §2`).
- [ ] No dependency installed from an untrusted source or with integrity verification disabled (`dependencies.md §4`).

---

## UI-Specific Checks *(apply only if Feature Type is UI/frontend)*

- [ ] Components are self-contained and reusable; presentational and container concerns are separated (`ui-design.md §5`).
- [ ] Overlays (modal, dialog, drawer) are self-contained components, not defined inline inside the component that opens them (`ui-design.md §5`).
- [ ] Every interactive component has its loading, error and disabled states (`ui-design.md §6`), and data views have an empty state (`ui-design.md §8`).
- [ ] No hardcoded visual values — design tokens for color, spacing and typography (`ui-design.md §13`).
- [ ] Layout uses relative units and responds to the target breakpoints (`ui-design.md §3`).
- [ ] A response for a selection the user has since navigated away from does not resolve into a currently-visible component's state (`ui-design.md §6`, `state-lifecycle.md §6`).

### Accessibility
- [ ] Every interactive element is reachable and operable by keyboard, with no keyboard trap (`accessibility.md §3`).
- [ ] Text and UI contrast meet WCAG AA (`accessibility.md §2`); focus is visible (`accessibility.md §4`).
- [ ] `aria-hidden="true"` is never present on a focusable element (`accessibility.md §5`).
- [ ] Every control has an accessible name; native semantic elements are used before ARIA (`accessibility.md §5`).
- [ ] Every form input has a programmatic label; errors are identified in text, not color alone (`accessibility.md §6`).

---

## API-Specific Checks *(apply only if Feature Type is backend/API)*

- [ ] HTTP method and semantics match the spec contract (`rest-api.md §2`) *(plan)*.
- [ ] Route path follows resource naming and matches the spec contract (`rest-api.md §1`) *(plan)*.
- [ ] Request/response body shapes match the spec (`rest-api.md §4`) *(plan)*.
- [ ] Status codes are correct — never `200` for an error (`rest-api.md §3`).
- [ ] No undocumented endpoint introduced (`rest-api.md §10`).
- [ ] A response reflects state as of completion, not data read before a concurrent write to the same resource finished (`concurrency.md §2`).

## Integration Consumption Checks *(apply only if the change calls an external service, API, or integration it does not control)*

- [ ] Every outbound call has an explicit timeout (`integration-consumption.md §1`).
- [ ] Retries only happen on idempotent operations or with an idempotency key, bounded with backoff (`integration-consumption.md §3`).
- [ ] A distinct failure state is exposed to callers — not indistinguishable from "still loading" (`integration-consumption.md §4`).
- [ ] The provider's raw response is parsed into an owned type at the boundary before reaching domain code (`integration-consumption.md §7`).

## Event-Driven Checks *(apply only if the change produces or consumes events, messages or streams)*

- [ ] Every consumer is idempotent against redelivery (`event-driven-architecture.md §2`).
- [ ] Schema changes are versioned and additive, never repurposing a field (`event-driven-architecture.md §3`).
- [ ] No consumer assumes delivery order without a partitioning/ordering key that guarantees it (`event-driven-architecture.md §4`).
- [ ] A failed event has a dead-letter path with alerting (`event-driven-architecture.md §5`).

---

## Design Patterns Checks *(apply only if the change introduces or extends a new abstraction, extension point, or variant-handling structure)*

- [ ] The pattern used solves a problem the code actually has — not applied because it's a recognizable name (`design-patterns.md §1`).
- [ ] An extension point was introduced only where a second concrete variant exists or is a stated near-term requirement (`design-patterns.md §3`).
- [ ] Where the codebase already solves this class of problem, the new code follows the existing pattern or explicitly justifies diverging (`design-patterns.md §2`).

---

## Review Document Template

Save to `docs/devflow/reviews/YYYY-MM-DD-{slug}-review.md`:

```markdown
# Code Review: {Feature Title}

**Date:** YYYY-MM-DD
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** {Cycle | Standalone}
**Invoking Agent:** {Implementer | Feature Agent | Refactorer | Bug-Fixer}
**Reference:** `docs/devflow/{specs|plans|features|refactors|bug-fixes}/{file}`

## Summary
{1-2 sentence overall assessment}

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |

### ❓ Open Questions *(optional — not findings, never affect the verdict)*
- {file:line} — {what would have to be true for this to be a defect; what to check}

## Coverage

> What this review actually examined. An APPROVED verdict is only as strong as this section: a dimension, standard or consumer that is not listed here was not reviewed.

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ / ⏭ {reason} | {list} | |
| 2 — Performance, Concurrency & Data | ✅ / ⏭ {reason} | {list} | |
| 3 — Architecture & Design | ✅ / ⏭ {reason} | {list} | Reference implementation compared: `{path}` / none — closest sibling `{path}` |
| 4 — Correctness & Behavior | ✅ / ⏭ {reason and signals} | — | Consumers read: {files} / none found — {how searched}; scenarios walked: {N}; open questions: {N} |
| 5a/5b/5c — Domain | ✅ {groups} / ⏭ no trigger | {list} | |

- **Review path:** parallel / inline — **diff signals present:** {S1…S6 or "none"} (`adaptive-skills.md` → Objective Diff Signals)
- **Deterministic checks:** `scan all` {clean / findings / skipped: {scanner}} · `scope audit` {clean / findings / n/a} · `traceability check` {clean / {N} rows uncovered / file missing}
- **Visual diff:** ran / skipped — {no vision / no UI}
- **Not covered:** {anything the review could not examine and why — or "nothing known"}

## Verdict
✅ APPROVED — no blockers | 🔄 CHANGES REQUESTED — {N} blockers
```