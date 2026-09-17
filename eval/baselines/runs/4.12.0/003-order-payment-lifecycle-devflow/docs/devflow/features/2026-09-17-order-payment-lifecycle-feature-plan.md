## ⚡ Feature Plan: order-payment-lifecycle

**Date:** 2026-09-17
**Agent:** DevFlow Feature Agent ⚡
**Stack:** Node.js (CommonJS) · none (raw `node:http`) · `node --test`

### Plan Digest

- **Tasks:** 2 tasks
- **Files to create:** none
- **Files to modify:** `src/orders.js`, `src/server.js`, `test/orders.test.js`
- **Key dependencies:** Task 1 (state machine + pay) → Task 2 (cancel reuses the same guard)
- **Test strategy:** unit per task + one sequence/interaction test (S1) for the concurrent-pay scenario
- **Scope:** in-memory only; no persistence layer; no new endpoints beyond pay/cancel

### Summary

**Goal:** Add `POST /orders/:id/pay` and `POST /orders/:id/cancel`, valid only while `pending`.

**Definition of Done:**
- [ ] `pay` charges via `payments.charge` and marks the order `paid` on success
- [ ] `cancel` marks the order `cancelled`
- [ ] Both are rejected unless the order is currently `pending`
- [ ] Unknown order id → 404 for both
- [ ] Existing create/read behaviour unchanged
- [ ] New behaviour covered by tests

### Scope

- **In:** `src/orders.js` (pay/cancel logic + guard), `src/server.js` (routes), tests
- **Out:** persistence, authentication, refunds

### Reference Implementation

- **File/Pattern:** `src/orders.js` `createOrder`/`getOrder` — same module-level `Map` store, plain-object clones on read, `ValidationError` pattern for typed errors.

### Affected Files

**Modify:**
- `src/orders.js` — add `payOrder`, `cancelOrder`, `NotFoundError`, `InvalidTransitionError`
- `src/server.js` — add the two routes and their error-to-status mapping
- `test/orders.test.js` — new tests

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | An order is `pending` | `pay` is called twice for the same order before the first charge settles | Exactly one charge is recorded and the order ends `paid` — the second call is rejected, not double-charged | Task 1 | `test/orders.test.js` |
| S2 | A charge is declined by the payments module | `pay` is called | The order stays `pending` and remains cancellable afterward | Task 1 | `test/orders.test.js` |
| S3 | An order is already `paid` or already `cancelled` | The other operation (`cancel`/`pay`) is called on it | The call is rejected — no backward transition | Task 2 | `test/orders.test.js` |

### Tasks

#### Task 1: State machine guard + pay operation

- **Standards constraints:** `concurrency.md §2` — the pending→paying transition must be claimed synchronously (an in-memory compare-and-set on the order's status field) before the async charge is awaited, so a second concurrent call sees a non-pending order and is rejected instead of racing the first call to the charge. `error-handling.md §6` — a declined charge must release the claim back to `pending`, not leave the order stuck in an intermediate state.

- [ ] **Test file:** `test/orders.test.js` (new tests appended to existing file)
  ```javascript
  // ✅ Happy path
  test('POST /orders/:id/pay charges the order and marks it paid', async () => {
    const created = await request('POST', '/orders', { amount: 300 });
    const res = await request('POST', `/orders/${created.body.id}/pay`);
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'paid');
  });

  // ⚠️ Edge case
  test('pay on an unknown order returns 404', async () => {
    const res = await request('POST', '/orders/does-not-exist/pay');
    assert.equal(res.status, 404);
  });

  // ❌ Failure / error scenario (S2)
  test('a declined charge leaves the order pending and it can still be cancelled', async () => {
    const created = await request('POST', '/orders', { amount: 999999 }); // above payments.MAX_CHARGE
    const payRes = await request('POST', `/orders/${created.body.id}/pay`);
    assert.equal(payRes.status, 402);
    const getRes = await request('GET', `/orders/${created.body.id}`);
    assert.equal(getRes.body.status, 'pending');
    const cancelRes = await request('POST', `/orders/${created.body.id}/cancel`);
    assert.equal(cancelRes.status, 200);
  });

  // 🔁 Sequence / interaction scenario — S1
  test('two simultaneous pay calls charge exactly once', async () => {
    const created = await request('POST', '/orders', { amount: 400 });
    const [r1, r2] = await Promise.all([
      request('POST', `/orders/${created.body.id}/pay`),
      request('POST', `/orders/${created.body.id}/pay`),
    ]);
    const statuses = [r1.status, r2.status].sort();
    assert.deepEqual(statuses, [200, 409]);
    const ledgerRes = await request('GET', '/ledger');
    const charges = ledgerRes.body.filter((c) => c.orderId === created.body.id);
    assert.equal(charges.length, 1);
  });
  ```

- [ ] **Production code:** `src/orders.js` (modify)
  ```javascript
  // Add alongside existing ValidationError:
  class NotFoundError extends Error {
    constructor(message) { super(message); this.name = 'NotFoundError'; }
  }
  class InvalidTransitionError extends Error {
    constructor(message) { super(message); this.name = 'InvalidTransitionError'; }
  }

  function requireOrder(id) {
    const order = orders.get(id);
    if (!order) throw new NotFoundError('order not found');
    return order;
  }

  // Claims pending -> paying synchronously (no await between the check and the
  // write), so a concurrent call sees a non-pending status and is rejected —
  // this is the compare-and-set concurrency.md §2 requires.
  async function payOrder(id) {
    const order = requireOrder(id);
    if (order.status !== 'pending') {
      throw new InvalidTransitionError(`order is ${order.status}, cannot pay`);
    }
    order.status = 'paying'; // claimed — synchronous, before any await
    try {
      await payments.charge(order.id, order.amount);
    } catch (err) {
      order.status = 'pending'; // release the claim on a declined charge
      throw err;
    }
    order.status = 'paid';
    return { ...order };
  }
  ```
  `getOrder` must present `paying` as `pending` to callers (it is an internal claim, not a public status) — modify it to map `paying` → `pending` in the returned clone.

- [ ] **Commit:**
  ```bash
  git add src/orders.js test/orders.test.js
  git commit -m "feat(orders): add pay operation with a pending->paying claim guard"
  ```

  **Test command:** `node --test test/orders.test.js`

---

#### Task 2: Cancel operation + route wiring

- **Standards constraints:** `error-handling.md §5` — map `NotFoundError` to 404, `InvalidTransitionError` to 409, and `PaymentDeclinedError` to 402 at the HTTP boundary, never leaking the raw error message structure beyond `{ error: message }`. `rest-api.md §3` — use the correct status code per outcome, never `200` for a rejected transition.

- [ ] **Test file:** `test/orders.test.js` (appended)
  ```javascript
  // ✅ Happy path
  test('POST /orders/:id/cancel marks the order cancelled', async () => {
    const created = await request('POST', '/orders', { amount: 120 });
    const res = await request('POST', `/orders/${created.body.id}/cancel`);
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'cancelled');
  });

  // ⚠️ Edge case
  test('cancel on an unknown order returns 404', async () => {
    const res = await request('POST', '/orders/does-not-exist/cancel');
    assert.equal(res.status, 404);
  });

  // ❌ Failure / error scenario (S3)
  test('a paid order cannot be cancelled, and a cancelled order cannot be paid', async () => {
    const a = await request('POST', '/orders', { amount: 50 });
    await request('POST', `/orders/${a.body.id}/pay`);
    const cancelPaid = await request('POST', `/orders/${a.body.id}/cancel`);
    assert.equal(cancelPaid.status, 409);

    const b = await request('POST', '/orders', { amount: 60 });
    await request('POST', `/orders/${b.body.id}/cancel`);
    const payCancelled = await request('POST', `/orders/${b.body.id}/pay`);
    assert.equal(payCancelled.status, 409);
  });
  ```

- [ ] **Production code:** `src/orders.js` (modify) + `src/server.js` (modify)
  ```javascript
  function cancelOrder(id) {
    const order = requireOrder(id);
    if (order.status !== 'pending') {
      throw new InvalidTransitionError(`order is ${order.status}, cannot cancel`);
    }
    order.status = 'cancelled';
    return { ...order };
  }
  ```
  In `server.js`, add routes:
  ```javascript
  ['POST', /^\/orders\/([^/]+)\/pay$/, async (req, res, [id]) => {
    send(res, 200, await orders.payOrder(id));
  }],
  ['POST', /^\/orders\/([^/]+)\/cancel$/, async (req, res, [id]) => {
    send(res, 200, orders.cancelOrder(id));
  }],
  ```
  And extend the catch block:
  ```javascript
  if (err instanceof orders.NotFoundError) return send(res, 404, { error: err.message });
  if (err instanceof orders.InvalidTransitionError) return send(res, 409, { error: err.message });
  if (err instanceof payments.PaymentDeclinedError) return send(res, 402, { error: err.message });
  ```

- [ ] **Commit:**
  ```bash
  git add src/orders.js src/server.js test/orders.test.js
  git commit -m "feat(orders): add cancel operation and wire pay/cancel routes"
  ```

  **Test command:** `node --test test/orders.test.js`

---

### Verification

**All new tests:** `node --test test/orders.test.js`
**Full suite:** `npm test`

---

## 🚦 Confirmation

Review the plan at `docs/devflow/features/2026-09-17-order-payment-lifecycle-feature-plan.md`.
If approved, the Feature Agent will implement each task following TDD (Red → Green).
