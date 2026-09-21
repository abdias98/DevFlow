## ⚡ Feature Plan: customer-cache

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript · Node.js (no framework) · node:test
**Rigor:** standard — 2 files, one new piece of in-memory state with a small set of sequence scenarios; no new component.

### Plan Digest

- **Tasks:** 2 tasks (T1 cache-on-read, T2 invalidation-on-write), both TDD Red → Green, one commit each.
- **Files to create:** none.
- **Files to modify:** `src/customers.js` (cache inside `createCustomerService`), `test/customers.test.js` (counting `fakeStore` + 12 new tests).
- **Key dependencies:** T2 builds on the cache introduced in T1.
- **Test strategy:** unit tests with the existing `fakeStore`, extended with a `calls.find` counter; sequence scenarios (in-flight find vs update, failure, overlap) are driven through the service, asserting observable results and, where the count IS the requirement, the number of store calls.
- **Scope:** no TTL, no size bound, no new options or files, no change to method signatures or to the store contract.
- **Design in one line:** cache the raw record's promise per id, apply the archived filter on every read, return a copy, evict the id when a write through the service settles.

### Summary

**Goal:** `getCustomer` serves a repeated lookup of the same customer without calling `store.find` again.

**Definition of Done:**
- [ ] A repeated `getCustomer` for the same id does not call `store.find` again (counted in a test).
- [ ] Results are unchanged: unknown -> null, archived hidden unless `includeArchived`, existing five tests still pass.
- [ ] `updateCustomer` / `archiveCustomer` are never masked by a stale cached value.
- [ ] The new behaviour and its sequences are covered by tests that failed before the change.

### Scope

- **In:** cache inside `createCustomerService`; tests for it.
- **Out:** TTL/eviction options, cross-process invalidation, store changes, docs beyond DevFlow artifacts.

### Reference Implementation

- **File/Pattern:** `src/customers.js` + `test/customers.test.js` — factory closure over the injected `store`, `'use strict'` CommonJS, `node:test` + `assert/strict`, one behaviour per `test(...)`, the `fakeStore` helper.

### Affected Files

**Create:** none.

**Modify:**
- `src/customers.js` — add the per-service cache and eviction on write.
- `test/customers.test.js` — `fakeStore` gains `calls` and exposes `rows`; new tests.

**Impact Zone:** none — `getCustomer`/`updateCustomer`/`archiveCustomer` signatures and return values are unchanged, there are no other dependents in the repository (`src/` has one file; `package.json` `main` only re-exports it).

### Standards Applied (design decisions)

| Standard | Decision |
|----------|----------|
| state-lifecycle.md §1/§3 | One owner (the service closure), one write path (the private `lookup`); dependency = the customer record; invalidation trigger = settle of `updateCustomer`/`archiveCustomer` for that id |
| state-lifecycle.md §6 | The map holds the `find` promise; eviction removes the entry, and a settled superseded promise only removes itself if it is still the current entry, so it can never repopulate the cache |
| state-lifecycle.md §8 | Key = id only, because the cached value (raw record) depends on nothing else; `includeArchived` is applied after the cache |
| performance.md §3 | Invalidation strategy present; TTL deliberately absent (staleness tolerance unknown, service is the sole writer) -> recommendation |
| concurrency.md §4/§6 | Overlapping lookups share one promise; nothing fire-and-forget; every promise is awaited by its caller |
| error-handling.md §2/§6 | Failures propagate unchanged and are never cached; a failed update evicts (outcome unknown) via `finally` |
| design-principles.md §2/§5 | No options, no classes, no new module; a `Map` and two small helpers |
| testing.md §2/§6/§9 | Arrange/Act/Assert, independent tests (each builds its own service+store), Red before Green |

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | customer c1 in the store | `getCustomer('c1')` twice | both return Ada, `store.find` called once | T1 | `test/customers.test.js` |
| S2 | c1 is archived | `getCustomer(c1, {includeArchived:true})` then `getCustomer(c1)`; and default first, then includeArchived | archived shown only when asked, in either order, one `find` | T1 | `test/customers.test.js` |
| S3a | c1 cached | `updateCustomer(c1,{name:'Grace'})` then `getCustomer(c1)` | returns Grace; c2 (other id) stays cached | T2 | `test/customers.test.js` |
| S3b | c1 cached | `archiveCustomer(c1)` then default and includeArchived lookups | null, then the archived customer | T2 | `test/customers.test.js` |
| S4 | a `find` for c1 is in flight (will return the old record) | `updateCustomer` completes, then the old `find` resolves, then `getCustomer(c1)` | returns Grace, not the old record | T2 | `test/customers.test.js` |
| S5a | `store.find` fails once | `getCustomer` fails, then again | second call reaches the store and returns the customer | T1 | `test/customers.test.js` |
| S5b | c1 cached, `store.update` applies the change then throws | `updateCustomer` rejects, then `getCustomer(c1)` | returns the changed record | T2 | `test/customers.test.js` |
| S6a | c1 not cached | two overlapping `getCustomer(c1)` | one `find`, both resolve | T1 | `test/customers.test.js` |
| S6b | c1 cached | caller mutates its result, then `getCustomer(c1)` | new result unaffected, a different object | T1 | `test/customers.test.js` |
| S7 | c1 unknown (null) | later c1 appears in the store, `getCustomer(c1)` | found (null was not cached) | T1 | `test/customers.test.js` |
| S8 (discovered) | an `updateCustomer(c1)` is running (write not yet at the store) | `getCustomer(c1)` during it, then the update settles, then `getCustomer(c1)` | the last lookup returns the updated record (eviction happens when the write settles, not when it starts) | T2 | `test/customers.test.js` |
| S9 (discovered) | lookup L1 of c1 in flight, an update evicts its entry, lookup L2 caches a newer entry | L1 then fails | L2's entry stays cached (a superseded lookup only removes itself) | T1 | `test/customers.test.js` |

### Tasks

#### Task 1: cache lookups in `getCustomer`

- **Standards constraints:** `state-lifecycle.md §8` — key by id only and cache the raw record, filter on read · `state-lifecycle.md §6` — cache the promise; a superseded entry only removes itself · `error-handling.md §2` — never cache a rejection or a miss · `concurrency.md §4` — every promise is awaited by its caller · `design-principles.md §2` — no options/TTL/new abstraction.

- [ ] **Test file:** `test/customers.test.js` — `fakeStore` counts calls and exposes its rows, then the S1, S2, S5a, S6a, S6b, S7 tests (full code in the file once written; shape below).
  ```js
  function fakeStore(initial) {
    const rows = new Map(initial.map((c) => [c.id, { ...c }]));
    const store = {
      rows,
      calls: { find: 0, update: 0 },
      async find(id) { store.calls.find += 1; const row = rows.get(id); return row ? { ...row } : undefined; },
      async update(id, changes) { store.calls.update += 1; const row = { ...rows.get(id), ...changes }; rows.set(id, row); return { ...row }; },
    };
    return store;
  }

  // S1 repeated lookup -> store.calls.find === 1
  // S1 different ids are cached separately
  // S2 includeArchived first then default -> null, find === 1 ; default first then includeArchived -> Ada, find === 1
  // S7 unknown id is not cached: add the row later, lookup finds it
  // S5a store.find rejects once; second lookup succeeds
  // S6a Promise.all of two lookups -> find === 1
  // S6b mutate first result; second lookup unaffected and not the same object
  ```

- [ ] **Production code:** `src/customers.js` *(modify)*
  ```js
  const cache = new Map(); // id -> Promise<raw record | undefined>
  function forget(id, entry) { if (cache.get(id) === entry) cache.delete(id); }
  function lookup(id) {
    const cached = cache.get(id);
    if (cached) return cached;
    const entry = store.find(id).then(
      (customer) => { if (!customer) forget(id, entry); return customer; },
      (error) => { forget(id, entry); throw error; },
    );
    cache.set(id, entry);
    return entry;
  }
  // getCustomer: const customer = await lookup(id); ...same filters...; return structuredClone(customer);
  ```

- [ ] **Commit:**
  ```bash
  git add src/customers.js test/customers.test.js
  git commit -m "feat(customers): cache getCustomer lookups per service instance"
  ```

  **Test command:** `node --test test/customers.test.js`

---

#### Task 2: evict the cache when a customer is written

- **Standards constraints:** `state-lifecycle.md §3` — the invalidation trigger sits next to the cache: `updateCustomer`/`archiveCustomer` evict the id when the write settles · `error-handling.md §6` — a failed write also evicts (`finally`), its outcome is unknown · `state-lifecycle.md §6` — S4 in-flight lookup must not repopulate a stale entry.

- [ ] **Test file:** `test/customers.test.js` — S3a, S3b, S4, S5b (full code in the file once written).
  ```js
  // S3a warm c1 and c2, update c1 -> c1 shows Grace (find 3 total), c2 still served from cache
  // S3b warm c1, archive c1 -> default null; includeArchived returns archived: true
  // S4  find gated after taking its snapshot; update completes; release gate; lookup -> Grace
  // S5b store.update applies the change then throws; updateCustomer rejects; lookup shows the change
  ```

- [ ] **Production code:** `src/customers.js` *(modify)*
  ```js
  async function write(id, changes) {
    try { return await store.update(id, changes); } finally { cache.delete(id); }
  }
  // updateCustomer -> write(id, changes); archiveCustomer -> write(id, { archived: true })
  ```

- [ ] **Commit:**
  ```bash
  git add src/customers.js test/customers.test.js
  git commit -m "feat(customers): evict the cached customer when it is updated or archived"
  ```

  **Test command:** `node --test test/customers.test.js`

---

### Verification

**All new tests:** `node --test test/customers.test.js`
**Full suite:** `npm test`

### Additional Recommendations (planning time)

- No TTL: a write to the store by another process is not seen until restart. If other writers exist, add a TTL or an event-driven invalidation (performance.md §3).
- No size bound: bounded in practice by the number of existing customers because misses are not cached.

---

## 🚦 Confirmation

CI mode: plan auto-approved.
