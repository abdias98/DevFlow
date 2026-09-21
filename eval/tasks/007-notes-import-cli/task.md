---
id: 007-notes-import-cli
title: Add a bulk import command to a notes CLI
complexity: routine
category: behavior
project: cli
classes: partial-failure, data-limits
threshold: 90
---

## Prompt

> The `notes` CLI stores notes in a JSON file and supports `add` and `list`.
> Add `notes import <file.json>`: the file holds an array of notes
> (`[{ "id": "...", "title": "..." }]`) and every one of them is added to the
> store. Cover the new behaviour with tests.

Seed the workspace first — `devflow-eval init 007-notes-import-cli <dir>` — then
give this exact prompt to the run under evaluation: once through `/devflow` (or
`/devflow-feature`) and once as a bare prompt to the same model. Score both
workspaces.

**Do not add anything to the prompt.** In particular, do not mention the
scenarios in *What the checks probe* below: the task measures whether the run
discovers them on its own.

## Definition of Done

- `notes import <file>` adds every note in the file.
- An import that cannot complete reports why and leaves the store as it was.
- The existing commands are unchanged.
- Tests cover the new command and the suite passes.

## What the checks probe

`bin/notes.js` is a real executable. Checks drive it through `probe.js` (kept
outside the workspace) as a child process against a throw-away store file, and
inspect stdout, stderr, the exit code and what `list` shows afterwards. Most
outcome weight sits on behaviour the request **implies** but does not spell out —
the defect classes a correctness review is expected to find (see
`docs/devflow-audit-review-quality.md` §1.1):

| Class | Scenario |
|---|---|
| Partial failure | A note in the middle of the file is invalid — the notes before it must not stay in the store |
| Partial failure | The error names the note that failed |
| Data limits | A file that is not JSON, or not an array, is a usage error — not a stack trace |
| Data limits | An empty array is valid and changes nothing |

The obvious implementation loops over the existing `add`. It is correct for
every valid file, and it writes the store once per note — so a bad third note
leaves two behind.

## Calibration

`reference/naive/` loops over `store.add`; `reference/correct/` validates the
whole file first and writes once (`store.addMany`). The checks are calibrated so
that the fixture alone, the naive reference and the correct reference score
clearly apart — `tests/devflow-eval.bats` asserts it.

## Scoring

Requires `node` ≥ 18. No service is started.
