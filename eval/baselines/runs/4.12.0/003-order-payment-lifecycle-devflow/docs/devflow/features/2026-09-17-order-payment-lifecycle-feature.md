# Feature Report: Order pay/cancel lifecycle

**Date:** 2026-09-17
**Agent:** DevFlow Feature Agent ⚡
**Stack:** Node.js (CommonJS) · none (raw `node:http`)

## Summary

**Goal:** Add `POST /orders/:id/pay` and `POST /orders/:id/cancel`, valid only while `pending`.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `pay` charges via `payments.charge` and marks the order `paid` on success | ✅ | `POST /orders/:id/pay charges the order and marks it paid` |
| 2 | `cancel` marks the order `cancelled` | ✅ | `POST /orders/:id/cancel marks the order cancelled` |
| 3 | Both rejected unless `pending` | ✅ | `a paid order cannot be cancelled, and a cancelled order cannot be paid` |
| 4 | Unknown order id → 404 | ✅ | `pay on an unknown order returns 404`, `cancel on an unknown order returns 404` |
| 5 | Existing create/read unchanged | ✅ | pre-existing 4 tests still pass unmodified |
| 6 | Covered by tests | ✅ | 7 new tests, 11/11 passing |

**Result:** 6/6 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/orders.js` | Modified | Added `payOrder`, `cancelOrder`, `NotFoundError`, `InvalidTransitionError`; `getOrder` maps the internal `paying` claim state to `pending` |
| `src/server.js` | Modified | Added `POST /orders/:id/pay` and `POST /orders/:id/cancel` routes; extended error→status mapping (404/409/402) |
| `test/orders.test.js` | Modified | 7 new tests: happy path ×2, 404 ×2, declined-charge, cross-transition, concurrent double-pay |

## Tasks Completed

- [x] Task 1: State machine guard + pay operation (includes the pending→paying claim, and cancel — needed by Task 1's own declined-charge test)
- [x] Task 2: Cancel operation + route wiring (routes and error mapping)

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/orders.test.js` | `POST /orders/:id/pay charges the order and marks it paid` | ✅ Passing |
| `test/orders.test.js` | `pay on an unknown order returns 404` | ✅ Passing |
| `test/orders.test.js` | `a declined charge leaves the order pending and it can still be cancelled` | ✅ Passing |
| `test/orders.test.js` | `two simultaneous pay calls charge exactly once` (S1) | ✅ Passing |
| `test/orders.test.js` | `POST /orders/:id/cancel marks the order cancelled` | ✅ Passing |
| `test/orders.test.js` | `cancel on an unknown order returns 404` | ✅ Passing |
| `test/orders.test.js` | `a paid order cannot be cancelled, and a cancelled order cannot be paid` (S3) | ✅ Passing |

**Verify with:**
- Single file: `node --test test/orders.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ no new external input beyond the existing `:id` path param, already guarded by 404 |
| Naming conventions | ✅ matches `createOrder`/`getOrder` (verb+Order, module-level Map, cloned reads) |
| SOLID principles | ✅ each function has one transition; no branching on order type |
| Test coverage | ✅ happy path, edge case, failure, and one sequence/interaction test per Behavior Scenario in the plan |

## Notes

The pending→paying claim is a synchronous field write before the async charge is awaited — this is what makes the two-simultaneous-pay scenario (S1, discovered as a Behavior Scenario during Step 1 brainstorming, before any code existed) resolve to exactly one charge instead of a race. A declined charge releases the claim back to `pending` (S2), so the order remains cancellable. No BLOCK findings from the Reviewer; one WARN (a documentation comment) and one INFO (burst-size test coverage) — both left for a future cycle, not required by the Definition of Done.
