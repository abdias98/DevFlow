# Feature Report: Customer lookup cache

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript · Node.js (no framework) · node:test
**Mode:** CI (plan auto-approved, tests auto-run, Standard-style execution) · **Rigor:** standard
**Plan:** `docs/devflow/features/2026-09-20-customer-cache-feature-plan.md`

## Summary

**Goal:** `getCustomer` serves a repeated lookup of the same customer without calling `store.find` again, without changing what it returns and without ever hiding a write made through the service.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | A repeated `getCustomer` for the same id does not call `store.find` again | ✅ | `test/customers.test.js:55` (find count 1 after two lookups), `:63` (two ids, 2 finds for 4 lookups), `:117` (overlapping lookups share one call); `src/customers.js:29-43` |
| 2 | Results unchanged: unknown -> null, archived hidden unless `includeArchived`, existing five tests pass | ✅ | Existing tests `:27-47` unchanged and passing; `:76`, `:85` (archived rule holds in both orders on one cached record); `:93` (a miss is not cached) |
| 3 | `updateCustomer` / `archiveCustomer` never masked by a stale cached value | ✅ | `:138` (update evicts, other ids stay cached), `:152` (archive evicts), `:161` (failed update still evicts), `:173` (lookup in flight during an update cannot restore the old record); `src/customers.js:46-54` |
| 4 | New behaviour and its sequences covered by tests that failed before the change | ✅ | Red confirmed before each Green: 5 of 8 new tests failed before Task 1, 4 of 4 before Task 2; the other 3 (`:93`, `:101`, `:126`) are guards for behaviour the change must not break and passed before it. `:173` also fails against a naive value-cache mutation (checked once, reverted) |

**Result:** 4/4 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/customers.js` | Modified | Per-service cache of the `find` promise keyed by id; archived rule applied after the cache; result copied per caller; single write path that evicts the id when a write settles |
| `test/customers.test.js` | Modified | `fakeStore` counts calls and exposes its rows; 14 new tests (12 planned + 2 added after the Reviewer's mutation reasoning) |

Commits: `6883534` (task 1), `664df66` (task 2), `6edd811` (two tests closing Reviewer findings 1 and 3; no production change).

No files created outside DevFlow artifacts. Scope additions: 0. Impact Zone edits: 0.

## Tasks Completed

- [x] Task 1: cache lookups in `getCustomer` — commit `6883534` `feat(customers): cache getCustomer lookups per service instance`
- [x] Task 2: evict the cache when a customer is written — commit `664df66` `feat(customers): evict the cached customer when it is updated or archived`
- [x] Review follow-up: two tests for eviction timing and superseded-lookup cleanup — commit `6edd811` `test(customers): pin eviction timing and superseded-lookup cleanup of the cache`

Branch `feat/customer-cache` (rollback checkpoint `pre-feature-impl` = `12d4a8d`). Nothing pushed.

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/customers.test.js` | a repeated lookup of the same customer does not go to the store again | ✅ passing |
| `test/customers.test.js` | different customers are looked up separately and each one is cached | ✅ passing |
| `test/customers.test.js` | an archived customer found with includeArchived stays hidden from a default lookup | ✅ passing |
| `test/customers.test.js` | an archived customer hidden by a default lookup is still found when asked for | ✅ passing |
| `test/customers.test.js` | an unknown customer is not cached: one that appears later is found | ✅ passing |
| `test/customers.test.js` | a failed lookup is not cached: the next lookup goes to the store again | ✅ passing |
| `test/customers.test.js` | overlapping lookups of the same customer share one store call | ✅ passing |
| `test/customers.test.js` | changing a returned customer does not change what later lookups return | ✅ passing |
| `test/customers.test.js` | updateCustomer evicts the cached customer; other customers stay cached | ✅ passing |
| `test/customers.test.js` | archiveCustomer evicts the cached customer | ✅ passing |
| `test/customers.test.js` | a failed update still evicts the cached customer | ✅ passing |
| `test/customers.test.js` | a lookup already in flight when a customer is updated does not leave the old record cached | ✅ passing |
| `test/customers.test.js` | a lookup made while an update is still running does not keep the old record cached | ✅ passing (discovered, S8) |
| `test/customers.test.js` | a superseded lookup that fails does not evict the newer cached entry | ✅ passing (discovered, S9) |

**Verify with:**
- Single file: `node --test test/customers.test.js`
- Full suite: `npm test` — run in this session: 19 tests, 19 pass, 0 fail.
- Lint/typecheck gate: none configured in the project (no script in `package.json`); nothing to run.
- `devflow-ctl scan all`: secrets clean, dependency scan clean, SAST skipped (semgrep not installed). `devflow-ctl scope audit`: clean.

## Behavior Scenarios

| # | Scenario | Test | Status |
|---|----------|------|--------|
| S1 | same customer twice -> one `find` | `:55`, `:63` | ✅ |
| S2 | archived record: includeArchived / default in either order -> one `find`, rule applied on read | `:76`, `:85` | ✅ |
| S3a/S3b | update / archive evicts the entry | `:138`, `:152` | ✅ |
| S4 | in-flight lookup vs update | `:173` | ✅ |
| S5a/S5b | failed find not cached / failed update evicts | `:101`, `:161` | ✅ |
| S6a/S6b | overlapping lookups share; caller mutation isolated | `:117`, `:126` | ✅ |
| S7 | miss not cached | `:93` | ✅ |

| S8 (discovered) | a lookup while an update is running must not keep the old record | `:197` | ✅ |
| S9 (discovered) | a superseded lookup that fails must not evict the newer entry | `:216` | ✅ |

S8 and S9 were found by the Reviewer's mutation reasoning (plan gaps: the code already handled them, no test pinned them). They were added to the plan's Behavior Scenarios as `(discovered)` and each fails against the mutant it targets.

## Self-Review

Inline self-review (standard rigor, 2 tasks, 2 files -> below the verifier threshold; no fresh-context verifier dispatched).

| Check | Result |
|-------|--------|
| Security | ✅ No external input beyond the id used as a `Map` key; no secrets; only existing customers are cached, so the cache cannot be grown by probing unknown ids |
| Naming conventions | ✅ Follows the file (camelCase, short comment blocks, closure over `store`) |
| SOLID principles | ✅ One factory, one private lookup path and one write path; no new abstraction |
| Design principles (YAGNI/KISS) | ✅ A `Map` and three small functions; no options, TTL or size bound |
| State lifecycle | ✅ owner = the closure; dependency = the record; eviction on write in one place; superseded lookup cannot restore an entry; key complete (id) because the archived rule is applied on read |
| Concurrency / async | ✅ Every promise is awaited by its caller; overlapping lookups share one call |
| Error handling | ✅ Failures propagate unchanged and are not cached; a failed write still evicts |
| Test coverage | ✅ Every decision point has a test. Mutation check by the Reviewer: 7 mutants, 2 survived initially, all killed after `6edd811` |
| Honesty check | Two limits are real and stated below: no TTL (out-of-band writes are invisible) and `structuredClone` assumes plain-data customers |

## Notes

- **Assumptions (CI)** are recorded in `docs/devflow/session/customer-cache/context.md` and summarised in the plan: per-instance in-memory cache; only found customers cached; service is the only writer; no TTL/size bound; a copy per caller.
- Overlapping-lookup sharing means a rejected `find` is delivered to every caller that joined it; the entry is removed so the next call retries.
- Reviewer verdict: APPROVED, 0 BLOCK, 2 WARN (one test gap fixed, one accepted no-TTL decision), 4 INFO — `docs/devflow/reviews/2026-09-20-customer-cache-review.md`. The review ran inline in this session (no fresh-context subagents), so its blind pass rests on ordering rather than isolation.
- Backlog: `D1` (info) — no TTL / out-of-band writes.

### Additional Recommendations

- **Staleness (performance.md §3):** if any other process or service writes customers to the store, `updateCustomer`/`archiveCustomer` cannot evict for it. Add a TTL (staleness tolerance is a business decision) or event-driven invalidation before that happens.
- **Unbounded growth:** the cache holds one record per customer ever read by this service instance. Bounded by the customer count today; add a size bound if the table is large relative to process memory.
- **Test helper:** `fakeStore` now lives only inside `test/customers.test.js`; if a second test file appears, move it to a shared helper (rule of three, design-principles.md §1 — not yet warranted).
