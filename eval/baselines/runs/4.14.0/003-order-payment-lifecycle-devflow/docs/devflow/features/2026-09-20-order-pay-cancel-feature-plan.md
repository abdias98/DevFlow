## ⚡ Feature Plan: order-pay-cancel

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (CommonJS) · node:http · node:test
**Rigor:** deep — irreversible external side effect (a charge) guarded by a check-then-act across an async call; needs concurrency tests

### Plan Digest

- **Tasks:** 2 tasks (cancel, then pay)
- **Files to create:** `test/order-actions.test.js`
- **Files to modify:** `src/orders.js`, `src/server.js`
- **Key dependencies:** Task 2 reuses the error classes and state guard introduced in Task 1
- **Test strategy:** HTTP-level tests (same style as `test/orders.test.js`) plus module-level deterministic tests with a controllable stub charge for the in-flight sequences; real concurrent requests for the double-charge invariant
- **Scope:** no auth, no refunds, no idempotency keys, no order listing, `src/payments.js` untouched
- **Design core:** a single guard `claimPending(id)` (synchronous, so it is atomic on the event loop) that rejects unknown / non-pending / payment-in-flight orders. `payOrder` claims the order (adds it to an in-flight set) BEFORE awaiting the charge and marks `paid` only after the charge succeeds; the claim is released in `finally`. `cancelOrder` uses the same guard, so it cannot interleave with an in-flight payment.

### Summary

**Goal:** Let a caller pay (through `payments.charge`) or cancel a `pending` order over HTTP, with each order charged at most once.

**Definition of Done:**
- [x] DoD1: `POST /orders/:id/pay` on a pending order charges the stored amount exactly once, sets `paid`, returns 200 + updated order
- [x] DoD2: `POST /orders/:id/cancel` on a pending order sets `cancelled`, returns 200 + updated order
- [x] DoD3: pay/cancel on a non-pending order -> 409, no charge, no state change; unknown order -> 404
- [x] DoD4: declined payment -> 402, order stays `pending`, ledger untouched
- [x] DoD5: new behaviour covered by tests, `npm test` passes

### Scope

- **In:** order state transitions, two routes, error-to-status mapping, tests
- **Out:** everything listed under "Scope" in the digest

### Reference Implementation

- **File/Pattern:** `src/orders.js` (copy-returning repository functions, error classes), `src/server.js` (route table, `handle` error mapping), `test/orders.test.js` (server bootstrap + `request` helper)

### Affected Files

**Create:**
- `test/order-actions.test.js` — pay/cancel tests

**Modify:**
- `src/orders.js` — `OrderNotFoundError`, `OrderStateError`, in-flight set, `cancelOrder`, `payOrder`
- `src/server.js` — two routes; map `OrderNotFoundError` -> 404, `OrderStateError` -> 409, `PaymentDeclinedError` -> 402

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | pending order | pay twice, one after the other | 200 then 409; ledger has exactly one entry for the order | Task 2 | `test/order-actions.test.js` |
| S2 | pending order | 3 concurrent pay requests | exactly one 200, others 409; exactly one ledger entry | Task 2 | `test/order-actions.test.js` |
| S3 | payment in flight (stub charge not yet resolved) | cancel arrives | cancel rejected (409); when charge resolves the order is `paid` | Task 2 | `test/order-actions.test.js` |
| S3b | pending order | pay and cancel requests race over HTTP | final status agrees with ledger: `paid` iff exactly one charge, `cancelled` iff none | Task 2 | `test/order-actions.test.js` |
| S4 | order with amount above the provider limit | pay | 402, order still `pending`, no ledger entry; cancel afterwards succeeds | Task 2 | `test/order-actions.test.js` |
| S5 | pending order | cancel, then pay / pay, then cancel | second op 409; no charge after cancel; `paid` stays `paid` | Task 1 / Task 2 | `test/order-actions.test.js` |
| S6 | no such order | pay / cancel | 404 on both | Task 1 / Task 2 | `test/order-actions.test.js` |
| S7 | charge fails with an unexpected error | pay | error propagates, order returns to `pending` (not stuck in flight), can be paid again | Task 2 | `test/order-actions.test.js` |
| S8 | pending order | cancel twice | 200 then 409 | Task 1 | `test/order-actions.test.js` |

### Tasks

#### Task 1: Cancel a pending order

- **Standards constraints:** `rest-api.md §3` — 200 with the updated order, 404 unknown, 409 state conflict; `error-handling.md §4/§5` — domain errors translated at the HTTP boundary, no internals in bodies; `testing.md §9` — Red first.

- [x] **Test file:** `test/order-actions.test.js` (server bootstrap copied from `test/orders.test.js`; cancel tests: happy path, unknown 404, twice 409, cancel does not charge)
- [x] **Production code:** `src/orders.js` — `OrderNotFoundError`, `OrderStateError`, `claimPending`, `cancelOrder`; `src/server.js` — `POST /orders/:id/cancel`, 404/409 mapping
- [x] **Commit:** `feat(orders): cancel a pending order`

  **Test command:** `node --test test/order-actions.test.js`

#### Task 2: Pay a pending order

- **Standards constraints:** `concurrency.md §2/§5` — check-then-act across the charge await made atomic by claiming synchronously before awaiting; real concurrent-request test for the "one charge per order" invariant; `error-handling.md §6` — claim released on every exit path; `integration-consumption.md §5` — the order is marked `paid` only after the charge succeeds; `rest-api.md §3` — 402 for declined payments; `security.md` — charge amount comes from the stored order, never the request body.

- [x] **Test file:** `test/order-actions.test.js` (append: happy path + ledger, ignores body amount, S1, S2, S3, S3b, S4, S5, S6, S7)
- [x] **Production code:** `src/orders.js` — `payOrder(id, charge)`; `src/server.js` — `POST /orders/:id/pay` (passes `payments.charge`), `PaymentDeclinedError` -> 402 with a generic message
- [x] **Commit:** `feat(orders): pay a pending order through the payments module`

  **Test command:** `node --test test/order-actions.test.js`

### Verification

**All new tests:** `node --test test/order-actions.test.js`
**Full suite:** `npm test`

---

### Additional Recommendations (pre-implementation)

- INFO: `/pay` and `/cancel` are verb-style URIs (`rest-api.md §1`), mandated by the request.
- INFO: no `Idempotency-Key` support (`rest-api.md §9`); retries are safe because a second pay gets 409.
- INFO: the in-flight guard is process-local; with a durable/multi-instance store it must become a conditional update (`concurrency.md §2`).
- INFO: `payments.charge` has no timeout (`integration-consumption.md §1`); an order stays claimed while a hung charge is outstanding. Payments module is outside scope.

## 🚦 Confirmation

CI mode: plan auto-approved.
