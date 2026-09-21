# Feature Report: Pay and cancel orders

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (CommonJS) · node:http · node:test

## Summary

**Goal:** Let a caller pay (through `payments.charge`) or cancel a `pending` order over HTTP, with each order charged at most once.

What was built: `POST /orders/:id/pay` and `POST /orders/:id/cancel`. Both go through one synchronous guard (`claimPending`) that rejects unknown orders (404), non-pending orders (409) and orders with a payment in flight (409). `payOrder` claims the order *before* awaiting the (50 ms) charge and marks it `paid` only after the charge succeeds, releasing the claim in `finally`, so concurrent pays cannot double-charge and a cancel cannot slip in while a charge is outstanding. A declined charge returns 402 and leaves the order `pending` with no ledger entry.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `POST /orders/:id/pay` on a pending order charges the stored amount exactly once, sets `paid`, returns 200 + updated order | ✅ | `test/order-actions.test.js` "pay charges the order amount once and marks it paid", "stored amount, not one from the request body", S2 (3 concurrent pays -> one charge) |
| 2 | `POST /orders/:id/cancel` on a pending order sets `cancelled`, returns 200 + updated order | ✅ | "cancel cancels a pending order and returns it", "cancel does not charge anything" |
| 3 | pay/cancel on a non-pending order -> 409, no charge, no state change; unknown order -> 404 | ✅ | S1, S5 (x2), S8, "pay returns 404 for an unknown order", "cancel returns 404 for an unknown order" |
| 4 | Declined payment -> error status, order stays `pending`, ledger untouched | ✅ | S4 (402, pending, no ledger entry, still cancellable), S7 (unexpected failure releases the order) |
| 5 | New behaviour covered by tests; `npm test` passes | ✅ | 16 new tests; `npm test`: 20 pass, 0 fail (stable over 6 repeated runs) |

**Result:** 5/5 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/orders.js` | Modified | `OrderNotFoundError`, `OrderStateError`, in-flight set, `claimPending`, `cancelOrder`, `payOrder(id, charge)` |
| `src/server.js` | Modified | `POST /orders/:id/pay`, `POST /orders/:id/cancel`; map not-found -> 404, state -> 409, `PaymentDeclinedError` -> 402 (generic body) |
| `test/order-actions.test.js` | Created | 16 tests: HTTP-level plus module-level deterministic in-flight sequences |

## Tasks Completed

- [x] Task 1: Cancel a pending order (commit `feat(orders): cancel a pending order`)
- [x] Task 2: Pay a pending order (commit `feat(orders): pay a pending order through the payments module`)

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/order-actions.test.js` | cancel: pending -> cancelled; no charge; unknown 404; S8 cancel twice 409 | ✅ Passing |
| `test/order-actions.test.js` | pay: happy path + ledger; stored amount; unknown 404 | ✅ Passing |
| `test/order-actions.test.js` | S1 pay twice; S2 concurrent pays; S3 cancel/pay during in-flight payment; S3b racing pay+cancel over HTTP | ✅ Passing |
| `test/order-actions.test.js` | S4 declined; S5 cancel-then-pay / pay-then-cancel; S7 unexpected charge failure | ✅ Passing |

Red was confirmed failing before each Green. A mutation check (removing the in-flight claim) makes S2 and S3 fail, so the concurrency tests do exercise the race.

**Verify with:**
- Single file: `node --test test/order-actions.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ amount from stored order, never request body; decline body is generic (no provider limit leaked) |
| Naming conventions | ✅ mirrors existing error-class / route-table style |
| SOLID principles | ✅ `orders.js` does not import `payments.js`; the charge function is injected by the route |
| Test coverage | ✅ every scenario S1-S8 has a test, including a real concurrent-request test |

## Notes

- Test files are tracked; the in-flight marker is process-local (in-memory service). With a durable or multi-instance store the claim must become a conditional update.
- INFO: `/pay` and `/cancel` are verb-style URIs (`rest-api.md §1`), mandated by the request. INFO: no `Idempotency-Key` (`rest-api.md §9`); retrying a pay is safe because the second call gets 409. INFO: `payments.charge` has no timeout, so a hung charge keeps its order claimed (payments module out of scope).

### Additional Recommendations

- Add a timeout/cancellation around `payments.charge` (`integration-consumption.md §1`) in the payments module.
- If the ambiguous case "charge timed out, outcome unknown" ever exists, `payOrder` releasing the order to `pending` could permit a double charge; reconcile against the ledger or use provider-side idempotency keys before adding a timeout.

### Reviewer outcome

APPROVED (0 BLOCK, 5 WARN, 9 INFO) — see `docs/devflow/reviews/2026-09-20-order-pay-cancel-review.md`. Deferred backlog: D1 (no authentication on the service, needs a user decision), D2 (no idempotency key / timeout for the charge against a real provider).
