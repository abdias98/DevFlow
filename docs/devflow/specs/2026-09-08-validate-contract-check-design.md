# Design Spec — Multi-agent contract integrity check (§15)

**Slug:** `validate-contract-check`
**Date:** 2026-09-08
**Finding:** F61 (Wave 17, Grupo A)
**Branch:** `feat/validate-contract-check`

## Spec Digest

- **Components:** new §15 section in `scripts/validate-framework.sh`; a `**Contract artifact:**` declaration line added to `shared/traceability-matrix.md` and `shared/metrics-template.md`; new `tests/validate-framework.bats`.
- **Data flow:** `shared/*.md` contract declarations → parse participants + artifact token → resolve human agent name to skill directory → assert the agent's `SKILL.md` references the artifact → ERROR on any gap.
- **Key decisions:** (1) reuse the existing `**<Verb> by:** <Agent>` prose convention instead of introducing YAML frontmatter — it already exists in 4 files and stays human-readable; (2) derive the grep token from the artifact basename by stripping `YYYY-MM-DD` / `{slug}` placeholders — empirically discriminating, see Design Decisions; (3) no production change for testability — bats drives the real script against a fixture tree via `cd`.
- **Risk:** 🟡 MEDIUM — a check that is too loose is worse than no check (false confidence). Mitigated by a mandatory negative test.
- **Test strategy:** bats, fixture-based; positive, negative and unknown-agent cases; plus a live acceptance test that reverts the F60 fix and asserts §15 fails.
- **API changes:** none.
- **UI changes:** none.

## Context

`validate-framework.sh` ships 14 checks. All 14 are **structural**: headings, template variables, cross-references, numbering, mandatory sections, lexical duplication. None of them verifies that a *behavioural contract* declared in one document is actually honoured by the agents that document names.

F60 is the proof. `shared/traceability-matrix.md` declared a four-step chain of custody — Planner writes → Implementer updates → Reviewer validates → Finalizer reports — but `devflow-implement/SKILL.md` and `devflow-review/SKILL.md` contained **zero** references to `traceability.md`. The contract was fiction for half its participants. All 14 checks passed. The gap was found only because a fork happened to run a real cycle and noticed the artifact was never produced.

That is the class this check closes: a declaration in `shared/` that silently loses a participant.

## Architecture

A new `§15 — Multi-agent contract integrity` appended to `scripts/validate-framework.sh`, following the established section idiom (`header`, `fail`/`warn`, guarded by a directory existence check, `green` on success).

```
for each shared/*.md containing a '**Contract artifact:**' line:
    artifact  := the declared path
    token     := basename(artifact) with YYYY-MM-DD / {slug} placeholders stripped
    for each '**<Verb> by:** <Agent>' line in the same file:
        skill_dir := AGENT_MAP[<Agent>]            # ERROR if unmapped
        assert grep -q token  <skill_dir>/SKILL.md # ERROR if absent
```

Discovery is driven by the presence of `**Contract artifact:**`, not by a hardcoded file list. A future `shared/` document earns the check by declaring the line — the validator needs no edit.

## Data Structures

**Declaration block** (added to the two contract documents, directly above the existing participant lines):

```markdown
**Contract artifact:** `docs/devflow/session/{slug}/traceability.md`
**Written by:** Planner (initial generation from spec + plan)
**Updated by:** Implementer (file paths + status per task)
**Validated by:** Reviewer (coverage check)
**Reported by:** Finalizer (coverage summary in final report)
```

**Agent name → skill directory map** (in the validator):

| Declared name | Skill directory |
|---------------|-----------------|
| Orchestrator  | `devflow` |
| Planner       | `devflow-plan` |
| Implementer   | `devflow-implement` |
| Reviewer      | `devflow-review` |
| Finalizer     | `devflow-finalize` |
| Architect     | `devflow-architect` |
| Brainstormer  | `devflow-brainstorm` |
| Debugger      | `devflow-debug` |

An unmapped name is a hard `ERROR`, never a skip — otherwise a typo (`Reviewr`) would silently disable enforcement for that participant, which is the exact failure mode this check exists to prevent.

**Token derivation rule:** `basename` → delete `YYYY-MM-DD`, `{slug}`, `{date}` → trim leading/trailing `-` → require ≥ 6 characters (a shorter token risks matching incidental prose).

| Artifact | Token |
|----------|-------|
| `docs/devflow/session/{slug}/traceability.md` | `traceability.md` |
| `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` | `metrics.md` |

## Reusability Decisions

| Existing component | Current purpose | Reusable for | Decision | Justification |
|---|---|---|---|---|
| `**<Verb> by:**` convention | Human documentation of who touches an artifact | Machine-readable participant list | **Reuse as-is** | Already present in 4 files with consistent shape; adding YAML frontmatter would duplicate the same fact in two places — exactly what `standards-dry-policy.md` forbids |
| §13 standalone matrix | Per-agent enforcement assertions | Generic contract checking | **Do not touch** | §13 hardcodes its 10 agents; folding it into §15 is a separate refactor with its own risk. Deferred to Wave 18 pending §15 proving its worth |
| `fail`/`warn`/`green` helpers | Accumulative error reporting | §15 reporting | **Reuse** | Section idiom is uniform across §1–§14 |

## Impact Analysis

| Component | Dependents | Likely coherence change needed? | Notes |
|---|---|---|---|
| `scripts/validate-framework.sh` | `package.json` (`npm run validate`), `.github/workflows/ci.yml` | No | Purely additive section; existing checks untouched |
| `shared/traceability-matrix.md` | `devflow-plan`, `devflow-implement`, `devflow-review`, `devflow-finalize` | No | One line added above an existing block; no participant semantics change |
| `shared/metrics-template.md` | `devflow`, `devflow-finalize` | No | Same |

## Concurrency Strategy

N/A — no concurrency-sensitive invariant. The validator is a single-pass, read-only script over the working tree.

## Test Architecture

| Layer/Area | Test types used | Tool | Available utilities | Reference test |
|---|---|---|---|---|
| §15 section logic | Fixture-driven behavioural tests | `bats` | `setup`/`teardown` with `BATS_TEST_TMPDIR`, `run`, `assert` via `[[ ]]` | `tests/devflow-ctl.bats` |
| Whole-framework regression | Live acceptance (revert-and-verify) | manual, recorded in review | `git stash` | — |

Test cases:

1. **Positive** — fixture where every declared participant references the token → §15 reports success, no `[ERROR]` line mentioning the artifact.
2. **Negative (the F60 shape)** — fixture where one participant's `SKILL.md` omits the token → §15 emits an `[ERROR]` naming that agent and artifact.
3. **Unknown agent** — declaration names `Reviewr` → §15 emits an `[ERROR]` about the unmapped name.
4. **No declarations** — `shared/` with no `**Contract artifact:**` line → §15 reports "no contracts declared", exits without error.
5. **Live acceptance** — revert commit `bcf08fc` (the F60 fix) in the real tree, run the real validator, assert §15 fails; restore.

Test 5 is the one that matters. A check that cannot demonstrate it would have caught the bug that motivated it has not earned its place in CI.

## Risk Assessment

| Risk | Level | Mitigation |
|---|---|---|
| Check is too permissive → false confidence, worse than no check | 🟡 MEDIUM | Mandatory negative test (case 2) + live acceptance (case 5); PR does not close without both green |
| Token too generic → matches incidental prose, everything passes | 🟡 MEDIUM | ≥6-char minimum; empirically verified that `metrics.md` scores 0 in the three non-participant agents, i.e. the token discriminates |
| Adds a 15th check to an already long validator run | 🟢 LOW | Section is grep-only over ~20 files; negligible next to §14's pairwise line comparison |

## Design Decisions

| Decision | Alternatives | Reasoning |
|---|---|---|
| Reuse `**<Verb> by:**` prose | YAML frontmatter block (my initial proposal) | The convention already exists in 4 files. Frontmatter would state the same fact twice and force every contract doc to carry a parser-shaped header for a human-readable document. Cheaper and less invasive to formalise what is already there. |
| Add explicit `**Contract artifact:**` line | Infer the artifact path from body prose | Inference over prose is exactly the brittleness §12's citation check keeps tripping on. One explicit line, two files, no ambiguity. |
| Discovery by declaration, not by file list | Hardcode the contract files, as §13 does for its 10 agents | §13's hardcoded list is the thing that made it un-reusable. Declaration-driven discovery means a new contract is covered the moment it is written. |
| No `SKILLS_DIR` env override; bats `cd`s into a fixture tree | Add `DEVFLOW_SKILLS_DIR` override for testability | The script already resolves `SKILLS_DIR` relative to CWD and guards every section with a directory check, so a fixture tree works with zero production change. Tests assert on §15's output lines rather than the process exit code, so unrelated sections warning about the fixture's missing dirs cannot cause a false pass or fail. |
| Unmapped agent name = ERROR | Skip unknown names with a warning | A silent skip on a typo disables enforcement for that participant — the precise failure mode being closed. |

## Constraints

- Bash 4+, GNU grep — same baseline as the rest of the script.
- `set -euo pipefail` is active: every `grep` in a pipeline or command substitution needs `|| true`.
- Must not raise the current run to a non-zero exit on `main` — the repository has to stay at 0 errors / 0 warnings after the change.
