# Code Review: Order pay/cancel lifecycle

**Date:** 2026-09-17
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Reference:** `docs/devflow/features/2026-09-17-order-payment-lifecycle-feature-plan.md`

## Summary
Two new operations (`pay`, `cancel`) added with a synchronous pending→paying claim guard that prevents double-charging under concurrent calls; error mapping is precise per outcome. No blockers found.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |
| — | — | — | None | — | — |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `src/orders.js` | `payOrder` | `getOrder` maps the internal `paying` state to `pending`, which is correct for external callers, but nothing documents this mapping next to the state literal itself | `design-principles.md §3` | Add a one-line comment at the `orders.set` claim site pointing to `getOrder`'s mapping, so the two stay in sync if a third internal state is ever added |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `test/orders.test.js` | S1 test | Only 2 concurrent `pay` calls are tested; a burst of 3+ is not, though the guard generalizes | `testing.md §4` | Optional: add a 3-way burst test if this endpoint is expected to see real concurrent traffic |

### ❓ Open Questions
- None.

## Coverage

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ | `security.md`, `error-handling.md` | No auth on this service (none existed before); no new input beyond the `:id` path param, already validated by 404-on-miss |
| 2 — Performance & Concurrency | ✅ | `performance.md`, `concurrency.md` | Claim-before-await pattern reviewed against `concurrency.md §2` — no I/O held under a lock (none used; compare-and-set via synchronous field write) |
| 3 — Architecture & Design | ✅ | `design-principles.md`, `solid.md`, `project-design.md`, `testing.md` | Follows `createOrder`/`getOrder` conventions (module-level Map, cloned reads, typed errors) — no divergence from the reference implementation |
| 4 — Correctness & Behavior | ✅ (blind pass performed) | — | Consumers read: `src/server.js` (only caller of `orders.payOrder`/`cancelOrder`), `test/orders.test.js`. Scenarios walked: 6 (both happy paths, both 404s, declined-charge-then-cancel, paid/cancelled cross-transition, concurrent double-pay). Mutation check: removing the synchronous claim write, or removing the decline rollback, both would be caught by existing tests. Open questions: 0 |
| 5a — Interfaces | ✅ | `rest-api.md` | Status codes: 200/404/409/402 — no `200` on a rejected transition |
| 5b — Presentation | ⏭ no trigger | — | No UI in this change |
| 5c — Operations | ⏭ no trigger | — | No logging or dependency changes in this diff |

- **Review path:** inline (single-file, low file count) — but Correctness & Behavior still ran, per policy.
- **Diff signals present:** S1 (control flow — new guard branches), S2 (state — order status field), S3 (side effect — `payments.charge`), S4 (contract — new routes)
- **Deterministic checks:** `scan all` → clean · `scope audit` → all justified (none needed) · `traceability check` → n/a (standalone mode has no traceability.md)
- **Visual diff:** skipped — no UI
- **Not covered:** load/stress testing beyond 2-way concurrency; nothing else known

## Verdict
✅ APPROVED — no blockers
