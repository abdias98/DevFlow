## ⚡ Feature Plan: stats-median

**Date:** 2026-09-20
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript · Node.js · node:test
**Rigor:** standard — routine small addition following an existing pattern

### Plan Digest

- **Tasks:** 2 tasks
- **Files to create:** none
- **Files to modify:** `src/commands.js`, `src/cli.js`, `test/cli.test.js`
- **Key dependencies:** Task 2 (usage text) independent of Task 1
- **Test strategy:** unit tests through the pure `run()` entry point, node:test
- **Scope:** no README/docs, no changes to parse.js or the other commands

### Summary

**Goal:** add `stats median <number...>`; `stats median 3 1 2` prints `2`.

**Definition of Done:**
- [ ] `median 3 1 2` -> `2\n`, exit 0
- [ ] even count -> mean of two middle values; order-independent; numeric (not text) ordering
- [ ] no numbers / non-numeric -> usage error like the other commands
- [ ] tests cover the above; `npm test` passes

### Scope

- **In:** `median` entry in `COMMANDS`; usage string; tests
- **Out:** other commands, parsing, docs

### Reference Implementation

- `src/commands.js` `mean`/`max` — go through `requireNumbers()`; `test/cli.test.js` — tests call `run([...])` and assert `stdout`/`code`/`stderr`.

### Affected Files

**Modify:**
- `src/commands.js` — add `median`
- `src/cli.js` — `USAGE` lists `median`
- `test/cli.test.js` — tests

### Behavior Scenarios

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|
| S1 | numbers in any order | `median 3 1 2` vs `median 2 3 1` | both print `2` | Task 1 | `test/cli.test.js` |
| S2 | an even count | `median 1 2 3 4` | prints `2.5` | Task 1 | `test/cli.test.js` |
| S3 | values of differing digit length | `median 10 9 2` | prints `9` (numeric ordering) | Task 1 | `test/cli.test.js` |
| S4 | no numbers | `median` | exit 1, stderr `median: no numbers given` | Task 1 | `test/cli.test.js` |
| S5 (discovered) | the two middle numbers sum beyond the float range | `median 1.7e308 1.7e308` | prints `1.7e+308`, never `Infinity` (a median lies between its inputs) | Task 1 | `test/cli.test.js` |

### Tasks

#### Task 1: median command

- **Standards constraints:** `design-principles.md §1` — reuse `requireNumbers` and the existing `COMMANDS` table, no new abstraction; `error-handling.md` — empty input is a UsageError, never NaN; `testing.md §4/§9` — happy path, edge, failure, each seen failing first.

- [ ] **Test file:** `test/cli.test.js`
  ```js
  test('median returns the middle number', () => {
    assert.deepEqual(run(['median', '3', '1', '2']), { code: 0, stdout: '2\n', stderr: '' });
  });
  test('median of an even count averages the two middle numbers', () => {
    assert.equal(run(['median', '1', '2', '3', '4']).stdout, '2.5\n');
  });
  test('median orders numerically, not as text', () => {
    assert.equal(run(['median', '10', '9', '2']).stdout, '9\n');
  });
  test('median of a single number is that number', ...);
  test('median with no numbers is a usage error', ...);
  test('median with a non-numeric argument names it', ...);
  ```

- [ ] **Production code:** `src/commands.js` (modify)
  ```js
  median: (numbers) => {
    const sorted = [...requireNumbers(numbers, 'median')].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  },
  ```

- [ ] **Commit:** `git commit -m "feat(stats): add median command"`
  **Test command:** `node --test test/cli.test.js`

---

#### Task 2: usage text

- **Standards constraints:** `design-principles.md §1` — USAGE is the single place listing commands.

- [ ] **Test file:** `test/cli.test.js` — `--help` output lists `median`.
- [ ] **Production code:** `src/cli.js` — `usage: stats <sum|mean|max|median> <number...>`
- [ ] **Commit:** `git commit -m "feat(stats): list median in usage text"`

---

### Verification

**All new tests:** `node --test test/cli.test.js`
**Full suite:** `npm test`
