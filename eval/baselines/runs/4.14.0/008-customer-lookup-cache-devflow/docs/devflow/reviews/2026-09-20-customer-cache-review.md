# Code Review: Customer lookup cache

**Date:** 2026-09-20
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Invoking Agent:** Feature Agent
**Reference:** `docs/devflow/features/2026-09-20-customer-cache-feature.md`
**Diff reviewed:** `git diff 12d4a8d..feat/customer-cache` (2 files: `src/customers.js`, `test/customers.test.js`), reviewed at commit `664df66`; findings 1 and 2 below were then closed by commit `6edd811` (tests only, no production change).

## Summary

The cache is correct on every traced path: it stores the raw record keyed by id, applies the archived rule on read, returns a copy, never remembers a miss or a failure, and evicts when a write settles. No defect in the production code. The review found two test gaps (mutations of the eviction timing and of the superseded-lookup cleanup survived the suite); both were closed with new tests and verified by re-running the mutants. No BLOCK.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| — | — | — | none | — | — |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `test/customers.test.js` | (before fix) 138-181 | Test gap, eviction timing. Mutant: evict the id *before* `store.update` starts instead of in `finally` (`src/customers.js:48-54`) survived all 17 tests | `testing.md §4` → WARN. scenario: c1 uncached, `updateCustomer` running (write not yet at the store) → `getCustomer(c1)` during it caches the old record → update settles → `getCustomer(c1)` → observed Ada forever with the mutant, expected Grace per the existing test `updateCustomer changes what getCustomer returns` and the module contract | Add a test that issues a lookup while the update is gated. **Resolved:** `test/customers.test.js:197` (`a lookup made while an update is still running…`); fails against the mutant, passes on the real code |
| 2 | `src/customers.js` | 12-22 (accepted) | Cache has no TTL; only this service instance evicts. A write by another process or by a second service instance over the same store is not seen until restart | `performance.md §3` → WARN (missing TTL). Deliberate decision (Assumption 5: service is the sole writer, staleness tolerance is unknown), surfaced in the plan and report | Recorded as backlog `D1` (info) and in Additional Recommendations. Not a blocker: no stated requirement is violated |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 3 | `test/customers.test.js` | (before fix) 138-181 | Test gap, superseded-lookup cleanup. Mutant: `forget` deletes unconditionally (`src/customers.js:25-27`) survived all tests; effect is a redundant store call, never a wrong result | `testing.md §4` → INFO (consequence limited to redundant work). scenario: lookup L1 in flight, update evicts, L2 caches a newer entry, L1 fails → observed L2's entry dropped, next lookup refetches; expected the newer entry kept per state-lifecycle.md §6 | **Resolved:** `test/customers.test.js:216` (`a superseded lookup that fails does not evict the newer cached entry`); fails against the mutant |
| 4 | `src/customers.js` | 63 | Contract change: `getCustomer` used to return the very object the store returned; it now returns a `structuredClone`. Consumers in the repo (only the tests) do not rely on identity; a customer holding non-cloneable values (functions) would throw `DataCloneError` | scenario: store returns a record with a function-valued field → `getCustomer` → observed `DataCloneError` at `src/customers.js:63`, expected the record per the documented shape `{ id, name, archived }` (plain data) → INFO, cannot occur with the documented shape | None needed; documented in the report |
| 5 | `src/customers.js` | 32 | `store.find(id).then(...)` requires `find` to return a real promise; before, `await store.find(id)` also tolerated a synchronous value | contract in the file header says `Promise<customer \| undefined>` → INFO, the contract is met by every caller | None needed |
| 6 | git history | `6883534` | Commit 1 alone caches without eviction (a warmed customer would stay stale after `updateCustomer`); the final state is correct | `git-conventions.md §1` → INFO (task-boundary commit that is coherent only with the next one) | None; plan prescribes one commit per task |

### ❓ Open Questions *(not findings, never affect the verdict)*
- `src/customers.js:19` — are several long-lived `createCustomerService` instances ever created over the same store (e.g. one per module)? If so, each has its own cache and an update through one is invisible to the others. Check the composition root once it exists; the repository has none today.

## Coverage

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ inline | security.md (quick-card triggers scanned; no input, secrets, queries or exposure change), error-handling.md | Failures propagate unchanged, never swallowed or cached; failed write evicts in `finally` |
| 2 — Performance, Concurrency & Data | ✅ inline | performance.md, concurrency.md, state-lifecycle.md | Owner, dependency, invalidation trigger, cache key, superseded-async guard all checked; data-persistence.md not applicable (no schema) |
| 3 — Architecture & Design | ✅ inline | design-principles.md, solid.md, testing.md, project-design.md skimmed (no file/module added), clean-architecture.md n/a (single module, no layers) | Reference implementation compared: `src/customers.js` and `test/customers.test.js` themselves (naming, closure over `store`, `node:test` style all followed) |
| 4 — Correctness & Behavior | ✅ inline, blind pass first (code, its only consumer `package.json` main, tests) then plan/report | — | Consumers read: none in the repo besides tests (searched with `grep -rn "customers" --include=*.js .`); scenarios walked: 12 (repetition, both archive orders, miss, failure, overlap, mutation of result, update, archive, failed update, in-flight vs update, lookup during update, superseded failure); mutants run: 7 (no clone, unconditional forget, miss cached, failure cached, evict on success only, evict before write, value-cache without identity check) — 2 survived initially (findings 1, 3), all killed after `6edd811`; open questions: 1 |
| 5a/5b/5c/5d — Domain | ⏭ no trigger | — | No endpoint/event/external call, no UI, no logging or manifest change, no new pattern (a `Map` and two helpers) |

- **Review path:** inline (sequential fallback, blind pass before reading the plan) — **diff signals present:** S1, S2, S3 (cache and store calls), S4 (return is now a copy), S6 (caching). The parallel dispatch of subagents was not used: the review ran inline in one context by the Feature Agent's own session, so the blind pass rests on ordering, not on isolation. That is a weaker guarantee than a fresh-context reviewer and is recorded here on purpose.
- **Deterministic checks:** `devflow-ctl scan all` clean (secrets clean, SCA clean, SAST skipped: semgrep not installed) · `scope audit` clean · `traceability check` n/a (a standalone Feature Agent cycle writes no `traceability.md`; noted as a gap, coverage is tracked in the plan's Behavior Scenarios instead)
- **Runtime verification:** skipped — rigor is `standard` (runs automatically only at `deep`/`maximum`); behaviour traced against code and pinned by unit tests.
- **Visual diff:** skipped — no UI.
- **Not covered:** behaviour against a real store implementation (only `fakeStore` exists in the repository); multi-process staleness (Open Question).

## Verdict
✅ APPROVED — no blockers
