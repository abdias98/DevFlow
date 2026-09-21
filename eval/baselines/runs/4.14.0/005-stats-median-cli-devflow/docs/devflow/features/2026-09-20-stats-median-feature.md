# Feature Report: stats median command

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript · Node.js · node:test

## Summary

**Goal:** Add a `median` command to the `stats` CLI so `stats median 3 1 2` prints `2`.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `stats median 3 1 2` prints `2`, exit 0 | ✅ | test `median returns the middle number regardless of argument order` (test/cli.test.js:37); runtime: `node bin/stats.js median 3 1 2` -> `2` |
| 2 | Even count -> mean of two middle values; order-independent; numeric ordering | ✅ | tests `median of an even count...`, `median orders numerically, not as text`, `median handles duplicates and negative numbers` |
| 3 | No numbers / non-numeric -> usage error like other commands | ✅ | tests `median with no numbers is a usage error`, `median with a non-numeric argument names it in the error`; runtime exit 1 |
| 4 | New behaviour covered by tests; `npm test` passes | ✅ | 16/16 passing (`npm test`) |

**Result:** 4/4 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/commands.js` | Modified | `median` entry in `COMMANDS`, via `requireNumbers`, numeric sort on a copy, overflow-safe even-count average |
| `src/cli.js` | Modified | `USAGE` lists `median` |
| `test/cli.test.js` | Modified | 10 new tests |

## Tasks Completed

- [x] Task 1: median command (commit `feat(stats): add median command`)
- [x] Task 2: usage text lists median (commit `feat(stats): list median in the usage text`)
- [x] Discovered (S5): median of two huge numbers must not overflow to Infinity (commit `fix(stats): keep median finite ...`), recorded in the plan as `(discovered)`

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/cli.test.js` | median returns the middle number regardless of argument order | ✅ passing |
| `test/cli.test.js` | median of an even count is the mean of the two middle numbers | ✅ passing |
| `test/cli.test.js` | median orders numerically, not as text | ✅ passing |
| `test/cli.test.js` | median of a single number is that number | ✅ passing |
| `test/cli.test.js` | median handles duplicates and negative numbers | ✅ passing |
| `test/cli.test.js` | median with no numbers is a usage error | ✅ passing |
| `test/cli.test.js` | median with a non-numeric argument names it in the error | ✅ passing |
| `test/cli.test.js` | the usage lists the median command | ✅ passing |
| `test/cli.test.js` | median of two huge numbers stays finite (discovered; both signs) | ✅ passing |
| `test/cli.test.js` | median keeps full precision when the sum does not overflow (subnormals) | ✅ passing |

Each test was seen failing before its production change (Red confirmed in CI mode).

**Verify with:**
- Single file: `node --test test/cli.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ input already validated finite by `parseNumbers`; no new surface |
| Naming conventions | ✅ follows `COMMANDS` table and `requireNumbers` convention |
| SOLID principles | ✅ one entry, one responsibility, no new abstraction |
| Test coverage | ✅ happy path, edge cases, failure paths, discovered overflow case |

Verifier subagent (fresh context): PASS, no BLOCK/WARN.

## Reviewer

Standalone review: APPROVED, 0 BLOCK / 0 WARN / 2 INFO (both test-adequacy gaps, closed with tests). See `docs/devflow/reviews/2026-09-20-stats-median-review.md`.

## Notes

- Assumption (CI): even-count median is the mean of the two middle values; empty input is a usage error per the codebase convention.
- `mean` and `sum` still overflow to `Infinity` on huge inputs. That is pre-existing and out of scope.

### Additional Recommendations
- **Plan gap (discovered):** the overflow case S5 was not in the original plan; it was added via Red -> Green and recorded in the plan.
- **Pre-existing:** `sum`/`mean` overflow to `Infinity` for huge finite inputs (`src/commands.js`).
