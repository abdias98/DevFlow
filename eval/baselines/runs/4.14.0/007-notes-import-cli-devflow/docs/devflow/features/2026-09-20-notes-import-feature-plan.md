## ⚡ Feature Plan: notes-import

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (Node >=18, CommonJS) · none · node:test
**Rigor:** standard — routine 3-file CLI addition with a partial-write risk to cover

### Plan Digest

- **Tasks:** 2 tasks (store batch-add; CLI `import` command)
- **Files to create:** none
- **Files to modify:** `src/store.js`, `src/cli.js`, `test/cli.test.js`
- **Key dependencies:** Task 1 (store `addMany`) -> Task 2 (CLI uses it)
- **Test strategy:** node:test through `run()` (as existing tests), temp store + temp import file per test
- **Scope:** no export, no merge/overwrite/skip policy, `add`/`list` behaviour unchanged

### Summary

**Goal:** `notes import <file.json>` adds every note in the file to the store.

**Definition of Done:**
- [ ] N valid notes in the file -> all N are in the store, in order, exit 0
- [ ] Same validation as `add` (id, title, unique id)
- [ ] Any failure (invalid note, duplicate within file or store, unreadable file, bad JSON, non-array) -> exit 1, stderr message, store unchanged
- [ ] Covered by tests; `npm test` passes

### Scope

- **In:** `import` subcommand, `store.addMany`, tests
- **Out:** export, conflict policies, format changes

### Reference Implementation

- `src/cli.js` `add` branch + `createStore().add` in `src/store.js` — same NoteError -> stderr/exit 1 convention, same test style (`run([...], { file })`, `tmpStore()`).
- Reuse `validateNote`; `add` becomes a one-note `addMany` so validation and duplicate logic live in one place (DRY).

### Affected Files

**Modify:**
- `src/store.js` — add `addMany(notes)` (validate all, reject duplicates within batch and vs store, one write); `add(note)` delegates to it
- `src/cli.js` — `import <file>` command, read + parse file (errors -> NoteError), usage text
- `test/cli.test.js` — import tests

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | store [n1] | import [n2,n3] | list = n1,n2,n3; exit 0; "imported 2 notes" | Task 2 | `test/cli.test.js` |
| S2 | file already imported | import it again | exit 1 duplicate id; store unchanged | Task 2 | `test/cli.test.js` |
| S3 | file with id `a` twice | import | exit 1 duplicate id: a; nothing added | Task 2 | `test/cli.test.js` |
| S4 | file [ok, ok, invalid] | import | exit 1 invalid note; store unchanged (no partial write) | Task 2 | `test/cli.test.js` |
| S5 | store [n1]; file [n2, n1] | import | exit 1 duplicate id: n1; n2 not added | Task 2 | `test/cli.test.js` |
| S6 | missing file / malformed JSON / non-array | import | exit 1, stderr message, store unchanged | Task 2 | `test/cli.test.js` |
| S7 | empty array | import | exit 0 "imported 0 notes"; store unchanged | Task 2 | `test/cli.test.js` |
| S8 | no file argument | `import` | exit 1 usage | Task 2 | `test/cli.test.js` |

### Tasks

#### Task 1: Atomic batch add in the store

- **Standards constraints:** `data-persistence.md` — multi-step write is all-or-nothing: validate everything before the single write. `design-principles.md` (DRY) — `add` delegates to `addMany`. `error-handling.md` — user mistakes are `NoteError`.

- [ ] **Test file:** `test/cli.test.js` (store-level cases exercised via the CLI in Task 2; Task 1 is verified by S3-S5 tests, which fail Red before `addMany` exists)
- [ ] **Production code:** `src/store.js` (modify)
  ```js
  addMany(notes) {
    notes.forEach(validateNote);
    const existing = readAll();
    const seen = new Set(existing.map((n) => n.id));
    for (const note of notes) {
      if (seen.has(note.id)) throw new NoteError(`duplicate id: ${note.id}`);
      seen.add(note.id);
    }
    if (notes.length === 0) return;
    writeAll(existing.concat(notes.map(({ id, title }) => ({ id, title }))));
  },
  add(note) { this.addMany([note]); },
  ```
- [ ] **Commit:** `feat(store): add atomic addMany batch operation`

  Note: Task 1 has no independent public entry point, so Red/Green is driven by the Task 2 tests (S3-S5 fail Red because `import` does not exist); the store change is committed together with the CLI change in one Red->Green cycle. **Test command:** `node --test test/cli.test.js`

#### Task 2: `notes import <file.json>`

- **Standards constraints:** `security.md` — external input (file content) is validated before use; errors carry no stack traces or file contents. `error-handling.md` — ENOENT / JSON.parse failures / non-array become `NoteError` (exit 1). `testing.md` §2/§9 — AAA, Red first, temp files only.

- [ ] **Test file:** `test/cli.test.js` — tests for S1-S8 (complete code written in Red phase, in the style of existing tests)
- [ ] **Production code:** `src/cli.js` (modify)
  ```js
  if (command === 'import') {
    const [importFile, ...extra] = rest;
    if (!importFile || extra.length) return { code: 1, stdout: '', stderr: USAGE };
    const notes = readNotesFile(importFile);
    store.addMany(notes);
    return { code: 0, stdout: `imported ${notes.length} note${notes.length === 1 ? '' : 's'}\n`, stderr: '' };
  }
  ```
  with `readNotesFile(path)` reading + `JSON.parse`, throwing `NoteError` for unreadable file, invalid JSON, or non-array.
- [ ] **Commit:** `feat(cli): add notes import command`

  **Test command:** `node --test test/cli.test.js`

### Verification

**All new tests:** `node --test test/cli.test.js`
**Full suite:** `npm test`

## Confirmation

CI mode: plan auto-approved.
