# Code Review: stats median command

**Date:** 2026-09-20
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Invoking Agent:** Feature Agent
**Reference:** `docs/devflow/features/2026-09-20-stats-median-feature.md`

## Summary
The `median` command is correct, follows the existing `COMMANDS`/`requireNumbers` convention, and is well tested. No BLOCK or WARN findings; two INFO test-adequacy gaps were raised and both were closed with tests.

## Findings

> **Evidence** is `{standard}.md §{N}` or a reproducible scenario, per rules.md Finding Evidence.

### 🔴 BLOCK (must fix)
None.

### 🟡 WARN (should fix)
None.

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | test/cli.test.js | 75-77 | Negative-overflow half of the overflow guard untested (`-1.7e308 -1.7e308`); mutant `(lo + hi) < Infinity` survived | testing.md §4 (Architecture and Correctness subagents, deduplicated) | Resolved: assertion added (commit 8b03a2a); mutant now fails the suite |
| 2 | test/cli.test.js | end | Guard's precision-preserving branch unpinned; always halving would print `0` for `5e-324 5e-324` | testing.md §4; scenario: `median 5e-324 5e-324` -> observed `0` under mutant, expected `5e-324` | Resolved: test added; mutant now fails the suite |

## Open Questions
- src/commands.js:26-29: comparator `a - b` can overflow to +-Infinity for opposite-sign huge values; sign stays correct and `parseNumbers` rejects non-finite input, so not reachable today.

## Additional Recommendations
- **Pre-existing:** `sum`/`mean` overflow to `Infinity` on huge finite inputs (backlog D1, info).

## Coverage

- **Review path:** dispatched parallel subagents (3 files changed). Diff signals: S1 (control flow) and S4 (contract: `USAGE`) present; S2, S3, S5, S6 absent.
- **Deterministic checks:** `devflow-ctl scan all` exit 0 (secrets clean, SCA clean, SAST skipped: semgrep not installed); `devflow-ctl scope audit` exit 0. Traceability check: no `traceability.md` for a standalone cycle, recorded as a gap.
- **Security & Safety (1):** loaded in full security.md, error-handling.md. No findings.
- **Performance, Concurrency & Data (2):** loaded in full performance.md; concurrency, state-lifecycle, data-persistence not applicable (no signals). No findings.
- **Architecture & Design (3):** loaded in full design-principles.md, solid.md, project-design.md, testing.md; clean-architecture.md not loaded (no layer/port). Reference: `mean`/`max` and existing tests. 1 INFO (resolved).
- **Correctness & Behavior (4):** blind pass then contrast pass. 3 units inventoried; consumers read: bin/stats.js, src/cli.js, src/parse.js, sibling commands; tests read: test/cli.test.js. 2 INFO (deduplicated with #1, both resolved). Runtime observation of `bin/stats.js` performed (median 3 1 2 -> 2, overflow, subnormal, empty, non-numeric).
- **Domain groups (5a-5d):** none triggered (no endpoint/event/integration, UI, logs/manifests, or new abstraction).
- **Visual diff:** skipped, feature has no UI. **Runtime verification:** not required at standard rigor; CLI probed by subagent 4.
- **Git conventions:** branch `feat/stats-median`, Conventional Commit messages.

## Verdict
✅ APPROVED
