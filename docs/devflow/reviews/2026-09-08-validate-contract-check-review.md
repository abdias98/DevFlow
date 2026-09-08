# Code Review — Multi-agent contract integrity check (§15)

**Slug:** `validate-contract-check`
**Date:** 2026-09-08
**Branch:** `feat/validate-contract-check`
**Reviewed against:** `docs/devflow/specs/2026-09-08-validate-contract-check-design.md`

## Summary

F61 adds §15 to `validate-framework.sh`: the first check in the script that verifies behaviour rather than structure. It reads the `**Contract artifact:**` + `**<Verb> by:** <Agent>` declaration block in `shared/` documents and asserts every named agent's `SKILL.md` actually references the governed artifact.

Two contracts are currently declared and both pass. The repository stays at **0 errors / 0 warnings**, and the full suite is at **148/148** bats tests (139 pre-existing + 9 new).

The deliverable is the check's *discriminating power*, not its existence, so the review weight sits on the negative evidence below rather than on style.

## Findings

### 🟢 The check catches the bug that motivated it — verified, not asserted

Reverting the F60 fix (`git checkout bcf08fc^ -- devflow-implement/SKILL.md devflow-review/SKILL.md`) and re-running the real validator:

```
== 15. Multi-agent contract integrity ==
[ERROR] devflow-implement/SKILL.md — declared in traceability-matrix.md as 'Implementer'
        for docs/devflow/session/{slug}/traceability.md, but does not reference
        'traceability.md' (F60-class: the contract names an agent that never touches
        the artifact)
[ERROR] devflow-review/SKILL.md — ... same, as 'Reviewer'
validator exit: 1
```

Both files restored afterwards; tree verified clean. This is R6 and it is the finding that justifies the PR. A check unable to reproduce a failure on the bug it was written for is decoration.

### 🟡 WARN — two real defects found during implementation, both by running

1. **Token derivation dropped only one separator.** `${t#-}` strips a single leading dash, but removing two adjacent placeholders from `YYYY-MM-DD-{slug}-metrics.md` leaves `--metrics.md`, so the token became `-metrics.md` and never matched a `SKILL.md` that says `metrics.md`. Fixed by collapsing separator runs (`sed -E 's/-+/-/g; s/^-//; s/-$//'`). Caught by the token-derivation test, not by reading the code — the same pattern as the four bash bugs in Wave 16.
2. **The test's section filter leaked the summary block.** `sed -n '/15. .../,$p'` ran to end-of-file, pulling in the final `Validation FAILED` line, which `red()` also prints as `[ERROR]`. Any fixture with an unrelated error would have looked like a §15 failure — a false-positive generator inside the test harness. Range now terminates at the summary rule.

Both are fixed and covered. Recording them because they are evidence for the Wave 17 rationale: the two defects in this PR were found by execution, and neither would have been caught by review.

### 🟡 WARN — one deliberate deviation from the plan

The plan specified three commits (Task 1 declarations, Task 2 §15, Task 3 tests). Delivered as **two**: the declarations, then §15 and its tests together. Committing the suite separately would have put a knowingly-red commit into `main`'s history and broken `git bisect` at that point. Flagged per the Implementer's deviation policy; the TDD order itself was honoured (9/9 red before §15 existed, 9/9 green after).

### 🟢 INFO — scope held

No changes outside the four scoped paths. §13 was left untouched as the spec specified; consolidating it into §15 remains a Wave 18 candidate, deliberately not attempted here. `.github/workflows/ci.yml` and `package.json` needed no edit — `bats tests/` already globs the new file, confirmed by the full-suite run.

### 🟢 INFO — a known limit of the check, stated rather than hidden

§15 verifies that a participant's `SKILL.md` *mentions* the artifact. It cannot verify that the mention is in the right place or does the right thing — a `SKILL.md` naming `traceability.md` in a comment would satisfy it. That is the same presence-not-correctness bargain `scan_secrets` and the F59 concurrency-task check already make, and it is the right one here: the failure mode being closed is a participant with *zero* connection to the artifact, which is exactly what F60 was.

## Verdict

**APPROVED.** All 8 traceability rows covered (`devflow-ctl traceability check` → 100%, 8/8). Spec and plan both pass `devflow-ctl artifacts check`. Repository validation green at 0/0, full suite 148/148, live acceptance reproduced and restored.

Two WARN findings are documented above and already resolved; neither blocks. No INCOMPLETE findings, so no deferred-backlog entries were required.
