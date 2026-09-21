# Code Review: notes-import

**Date:** 2026-09-20
**Review Mode:** Standalone (invoked by Feature Agent)
**Reference:** `docs/devflow/features/2026-09-20-notes-import-feature.md`

## Verdict

✅ APPROVED — 0 BLOCK, 4 WARN (2 fixed, 2 deferred to backlog), several INFO.

## Summary

`notes import <file.json>` adds every note in the file via a new all-or-nothing `store.addMany`; `add` delegates to it. 20/20 tests pass (`npm test`).

## Findings

### 🔴 BLOCK
None.

### 🟡 WARN
| # | File:Line | Issue | Evidence | Resolution |
|---|-----------|-------|----------|------------|
| W1 | src/store.js:34-44 | Two concurrent processes doing read-modify-write on the store can lose a whole batch while both report success. Reproduced with two parallel 200k-note imports. Root cause pre-existing in `add`; window is wider for a batch | concurrency.md §2 (quick card BLOCK trigger for shared state); rated WARN because the tool is single-user and the defect predates the diff | Deferred: backlog D3 (incomplete) |
| W2 | src/store.js:9-17 | New trust boundary (file input): no bound/format on `id`, control chars allowed, so `list` can echo forged lines/ANSI escapes | security.md §1 -> WARN | Deferred: backlog D4 (info); tightening `validateNote` also changes `add` |
| W3 | src/cli.js:14-22 | Import file errors dropped the original cause / JSON position | error-handling.md §3 -> WARN | **Fixed** (commit fix(cli): chain error causes...): `cause` chained, parse message included |
| W4 | test/cli.test.js | Several failure scenarios bundled in one test (testing.md §2 -> WARN) | testing.md §2 | **Fixed**: split into one test per scenario |

### 🟢 INFO
- src/store.js:26-28 non-atomic `writeAll`; corrupt/unwritable store surfaces raw stack (pre-existing, backlog D1, D2).
- Error for a non-object entry does not name its index (backlog D5). Numeric ids and BOM-prefixed files are rejected (fail safely, exit 1).
- Store tests live in `cli.test.js` (backlog D6, testing.md §7).
- Whole-file synchronous reads, no size cap (performance.md §1/§4).

## Correctness & Behavior (blind pass, then contrast)
No traced defect against the DoD. Mutation reasoning: every plausible single mutation on validation, duplicate check, append, field strip, empty-array, usage, and the three file-error branches is killed by an existing test. Open questions: store crash-safety, BOM tolerance, numeric ids (all deliberate / out of scope).

## Coverage
- **Review path:** parallel subagents (3 dispatched: Security+Performance/Data, Architecture, Correctness). Diff signals present: S1 (control flow), S2 (state, persisted JSON), S3 (file I/O), S4 (contract: new `addMany`, `add` delegation, CLI command), S5 (input parsing of external file). S6 not present.
- **Standards loaded in full:** security, error-handling, performance, state-lifecycle, data-persistence, design-principles, solid, clean-architecture, project-design, testing, git-conventions. concurrency.md not loaded (no async code; multi-process race cited via quick card and reproduction).
- **Domain subagent 5:** not dispatched (no endpoint, event, UI, logging, dependency or pattern change).
- **Deterministic checks:** `devflow-ctl scan all` clean (secrets clean, SCA clean, SAST skipped: semgrep not installed); `devflow-ctl scope audit` OK; traceability check not applicable (no `traceability.md` for a standalone feature).
- **Correctness & Behavior:** consumers read: `bin/notes.js` (only consumer of `run`); tests read: `test/cli.test.js`. Units inventoried: 5.
- **Visual diff:** skipped — feature has no UI. **Runtime verification:** skipped — rigor below deep (CLI additionally exercised manually by the Feature Agent).
- **Git conventions:** branch `feat/notes-import`, Conventional Commit messages: clean.

## Open Questions
- Crash-safety of the store write, BOM tolerance, and numeric ids: confirm with the requester if they are requirements.

### Additional Recommendations
- **Persistence/concurrency:** lockfile or temp-file + rename for store writes (backlog D3, D1).
- **Validation:** bound ids and reject control characters at all entry points (backlog D4).
