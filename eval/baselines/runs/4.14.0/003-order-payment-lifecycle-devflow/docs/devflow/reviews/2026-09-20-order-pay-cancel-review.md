# Code Review: Pay and cancel orders

**Date:** 2026-09-20
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Invoking Agent:** Feature Agent
**Reference:** `docs/devflow/features/2026-09-20-order-pay-cancel-feature.md`

## Summary

`POST /orders/:id/pay` and `/cancel` are implemented behind one synchronous guard, so an order is charged at most once and cannot be cancelled while a charge is in flight; verified by static review from five dimensions, by the test suite and by a live runtime run. No blockers. Five warnings remain, all concerning robustness against a real payment provider or the service's missing auth, none reproducible with the in-repo simulated gateway.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| — | — | — | None. (Subagent 1 raised missing authentication as BLOCK; the Reviewer downgraded it to WARN #1 — see the note under the table.) | | |

> **Severity note on W1.** `security.md §2` makes an unauthenticated mutating endpoint a BLOCK. Here the entire service (`POST /orders`, `GET /orders/:id`, `GET /ledger`) has no identity model at all, so there is no caller identity or order owner to check; adding authentication is a new capability, not part of "add pay and cancel", and is outside the approved scope and the request. Unsure between BLOCK and WARN, the lower level is chosen (rules.md → Behavioral Impact Severity) and the decision is left visible: **the user should decide whether this service may expose charging endpoints unauthenticated.** Recorded in the deferred backlog.

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| W1 | src/server.js | 39-44 | New money-moving and state-changing endpoints have no authentication/authorization or ownership check; order ids are sequential and guessable | `security.md §2 → WARN` (service-wide pre-existing gap; downgraded, see note) | Add an auth layer and owner check in a dedicated change; use non-guessable ids |
| W2 | src/server.js | 39-40 | No rate limiting on the pay endpoint | `security.md §7 → WARN` | Per-caller rate limit once callers are identified |
| W3 | src/orders.js | 72-77 | Ambiguous charge failure releases the order to `pending` with no idempotency key; a client retry could double-charge a real provider | `integration-consumption.md §3 → WARN`, `concurrency.md §5`; scenario: provider charges, response lost → `charge` throws → `finally` releases (orders.js:75-77) → client re-POSTs `/pay` → second charge; expected one charge per order per DoD1. Cannot occur with the simulated gateway (ledger push is its last statement, payments.js:32) | Pass a stable idempotency key (`pay:{orderId}`) to `charge`; release only on definite failures (`PaymentDeclinedError`), reconcile against the ledger otherwise |
| W4 | src/orders.js | 73 | No timeout on `charge`: a hung charge leaves the order permanently in-flight (pay and cancel both 409) until restart | `integration-consumption.md §1 → WARN`, `performance.md §4` | Bounded timeout mapped to 504; must be combined with W3 (unknown outcome) |
| W5 | src/orders.js | 73 | Caller cancellation (client disconnect) does not reach the gateway call; the charge completes and the order becomes `paid` | `integration-consumption.md §2 → WARN` | Thread an `AbortSignal`, or record that a started charge is deliberately not abortable (current behavior is the safe outcome) |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| I1 | src/server.js | 39, 42 | Verb-style URIs, mandated by the request | `rest-api.md §1 → INFO` | None |
| I2 | src/server.js | 39-41 | No `Idempotency-Key`; repeat pay/cancel returns 409 instead of the prior result | `rest-api.md §9 → INFO` | Optional; 409 keeps a repeat safe |
| I3 | src/server.js | 63-64 | Non-decline gateway failures surface as generic 500 (looks like an internal bug) | `rest-api.md §3`, `integration-consumption.md §4 → INFO` | Introduce a gateway error type mapped to 502/504 |
| I4 | src/orders.js | 6-8, 55 | In-flight state is a second process-local store (`paying`); `GET` reads `pending` while a charge is outstanding; not cross-instance safe | `state-lifecycle.md §1 → INFO`, deliberate per plan | Conditional update / explicit status when a real store arrives |
| I5 | src/orders.js | 73 | `charge` result is discarded; `chargeId` is not stored on the order | `integration-consumption.md §7 → INFO` | Store/validate `chargeId` |
| I6 | src/orders.js | 47-56 | `claimPending` only validates; the actual claim is `paying.add` in `payOrder`, atomicity relies on no `await` between them | `solid.md §1 → INFO` | Rename `assertPending` or merge |
| I7 | src/orders.js, src/server.js | 12-31, 60-62 | Error classes and `instanceof` chain grow per error type; `PaymentDeclinedError` (a payments type) is mapped in the HTTP layer | `design-principles.md §1`, `clean-architecture.md §2 → INFO` | None now |
| I8 | test/order-actions.test.js | 195 | No HTTP-level test for the generic 500 path (S7 is module-level only); a plausible mutation of the 500 fallback survives | `testing.md §4 → INFO` (plan gap, scenario S7 scoped to module level) | Add an HTTP test with a stubbed throwing `payments.charge` |
| I9 | test/order-actions.test.js | 113, 148-165 | Local `before` shadows the node:test hook import; S3b branches on the race outcome (pay always wins in practice) | `testing.md §2/§6 → INFO` | Rename variable; optional |

### ❓ Open Questions *(optional — not findings, never affect the verdict)*
- src/orders.js:73-77 — if a real gateway can record a charge and then fail to respond, W3 becomes a real double-charge path; is that gateway behavior possible for the provider this stub stands in for?
- src/orders.js:34 vs src/payments.js:10 — `createOrder` accepts amounts above `MAX_CHARGE`; such orders can only be cancelled. Consistent with S4; confirm that is intended.

## Coverage

> What this review actually examined. An APPROVED verdict is only as strong as this section: a dimension, standard or consumer that is not listed here was not reviewed.

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ | security.md, error-handling.md | Quick Card BLOCK triggers scanned first |
| 2 — Performance, Concurrency & Data | ✅ | performance.md, concurrency.md, state-lifecycle.md | data-persistence.md not loaded: no persisted schema |
| 3 — Architecture & Design | ✅ | design-principles.md, solid.md, clean-architecture.md, project-design.md, testing.md | Reference implementation compared: `src/orders.js`, `src/server.js`, `test/orders.test.js` |
| 4 — Correctness & Behavior | ✅ | — | Consumers read: `src/payments.js`, `test/orders.test.js`; scenarios walked: 14; open questions: 4 (2 carried above, 2 already recorded as deliberate in the plan) |
| 5a — Domain (Interfaces) | ✅ | rest-api.md, integration-consumption.md | 5b/5c/5d: ⏭ no trigger (no UI, no logging/dependency change, no new pattern) |

- **Review path:** parallel — **diff signals present:** S3 (side effect: charge), S4 (contract: two new endpoints), S5 (security surface) (`adaptive-skills.md` → Objective Diff Signals)
- **Deterministic checks:** `scan all` clean (semgrep SAST skipped: not installed) · `scope audit` clean · `traceability check` file missing (standalone Feature Agent produces no traceability.md; behavior scenarios are tracked in the plan)
- **Runtime verification:** ran — started `node src/server.js`; race of two pays plus a cancel gave one 200 and two 409, ledger had exactly one entry, order ended `paid`; a 20000-amount order returned 402, stayed `pending` and was then cancellable; unknown order 404; ledger untouched by the decline. Matches S1-S6 (and the same sequences in the test suite: 20/20 passing, stable across 6 runs, mutation check confirms S2/S3 detect a missing claim)
- **Visual diff:** skipped — no UI
- **Git conventions:** branch `feat/order-pay-cancel`; commits `feat(orders): cancel a pending order` and `feat(orders): pay a pending order through the payments module` (imperative, under 72 chars, `type(scope): description`) — conform (`git-conventions.md §1/§2`)
- **Not covered:** SAST (semgrep unavailable); no real payment provider behavior (only the in-repo simulator)

## Verdict
✅ APPROVED — no blockers (5 WARN, 9 INFO)
