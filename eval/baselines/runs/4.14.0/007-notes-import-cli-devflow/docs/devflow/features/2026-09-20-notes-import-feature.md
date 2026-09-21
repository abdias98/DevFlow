# Feature Report: notes import

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (Node >=18, CommonJS) · none · node:test

## Summary

**Goal:** `notes import <file.json>` reads an array of `{id, title}` notes and adds every one of them to the store, all-or-nothing.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | N valid notes in the file -> all N in the store, in order, exit 0 | ✅ | `import adds every note in the file after the existing ones`; runtime check via `bin/notes.js` |
| 2 | Same validation as `add` (id, title, unique id) | ✅ | `addMany` calls `validateNote`; `import with an invalid note later in the file adds nothing`; `add` now delegates to `addMany` (existing add tests pass) |
| 3 | Any failure -> exit 1, stderr message, store unchanged | ✅ | tests: repeated import, id repeated inside file, id already in store, invalid note, non-object entry, unreadable file / bad JSON / non-array, usage; `store.addMany is all-or-nothing...` |
| 4 | Covered by tests; `npm test` passes | ✅ | 20 tests, 20 pass |

**Result:** 4/4 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/store.js` | Modified | `addMany(notes)`: validate all, reject duplicates within the batch and vs the store, single write; `add` delegates to it |
| `src/cli.js` | Modified | `import <file.json>` command, `readNotesFile` (unreadable / invalid JSON / non-array -> `NoteError`), usage text |
| `test/cli.test.js` | Modified | 4 store-level tests and 12 CLI import tests (split per scenario after review) |

## Tasks Completed

- [x] Task 1: atomic batch add in the store (`feat(store): add atomic addMany batch operation`)
- [x] Task 2: `notes import <file.json>` (`feat(cli): add notes import command`)

## Behavior Scenarios

| # | Scenario | Test |
|---|----------|------|
| S1 | import into existing store | `import adds every note in the file after the existing ones` |
| S2 | import same file twice | `importing the same file twice fails the second time and changes nothing` |
| S3 | id repeated inside file | `import with an id repeated inside the file adds nothing` |
| S4 | invalid note later in file | `import with an invalid note later in the file adds nothing` |
| S5 | id already in store | `import with an id already in the store adds none of the new notes` |
| S6 | unreadable / malformed / non-array | `import reports an unreadable file, malformed JSON or a non-array as an error` |
| S7 | empty array | `import of an empty array succeeds and leaves the store untouched` |
| S8 | wrong arguments | `import without exactly one file argument prints the usage` |

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/cli.test.js` | store.addMany (4 tests: append/strip, 3 all-or-nothing cases) | ✅ Red confirmed, then passing |
| `test/cli.test.js` | import (12 tests) | ✅ Red confirmed, then passing |

**Verify with:**
- Single file: `node --test test/cli.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ File content validated before use; errors show path only, no stack or file contents; path is a user CLI argument (local tool) |
| Naming conventions | ✅ Follows existing style |
| SOLID principles | ✅ Validation/duplicate logic in one place (`addMany`); `add` reuses it |
| Test coverage | ✅ Happy path, edges, failure and partial-failure sequences |

## Notes

- Reviewer verdict: APPROVED (`docs/devflow/reviews/2026-09-20-notes-import-review.md`); follow-up commit `fix(cli): chain error causes and split import failure tests` addressed two WARNs. Deferred backlog: D1-D6 (`devflow-ctl backlog list`).

- Assumption (CI): "every one of them is added" is implemented as all-or-nothing; duplicates are errors (no merge/skip).
- Scope: only the three files declared at init; no scope additions.

### Additional Recommendations
- **Persistence:** `writeAll` is a non-atomic `writeFileSync` (backlog D1, info).
- **Error handling:** a corrupt store file surfaces as an uncaught SyntaxError with stack trace for add/list/import (backlog D2, info).
- **Performance:** import reads the whole file into memory; fine for a notes tool, unbounded for huge files (info).
