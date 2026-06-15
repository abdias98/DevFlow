# DevFlow — Improvement Roadmap

> Status tracking for the framework improvement effort. One branch + PR per finding.
> Source analysis: 2026-06-15. Decisions: Unreleased + release-per-wave versioning; wire orphan
> templates; full standards set (logging, error-handling, concurrency, dependencies, a11y);
> phase renumber deferred to a final major.

## Rules for every PR

- Branch per `git-conventions.md §2` (`fix/`, `refactor/`, `feat/`, `chore/`, `docs/`). Never commit to `main`.
- Conventional Commits, one logical change per commit.
- `npm run validate` must pass (zero errors).
- Add notes under `## [Unreleased]` in `CHANGELOG.md`. Do **not** bump `package.json` except in release PRs.
- If a SKILL step structure changes visibly, check its mirror `.prompt.md`.
- The user opens the PR — agents never run `gh pr create`.

---

## Wave 1 — Concrete defects (correctness)

| PR | Branch | Finding | Files | Status |
|----|--------|---------|-------|--------|
| PR1 | `fix/review-phase-numbering` | Reviewer labeled Phase 5 (should be 6); routing to "Phase 7 (Finalizer)" (should be 8) | `devflow-review/SKILL.md` | ✅ #40 |
| PR2 | `fix/bugfix-duplicate-step9` | Duplicate "Step 9" heading | `devflow-bug-fix/SKILL.md` | ✅ #41 |
| PR3 | `fix/orphan-reference-templates` | 4 templates unreferenced → wire into Architect/Planner stack flow | `devflow-architect/SKILL.md`, `devflow-plan/SKILL.md` | ✅ #42 |
| PR4 | `fix/debugger-mode-alignment` | Debugger ignores Standard/Pair/CI mode (always asks user) | `devflow-debug/SKILL.md` | ✅ #43 |
| — | `chore/release-wave-1` | Bump + sync package.json/lock/CHANGELOG | release | ☐ |

## Wave 2 — Structural agent improvements

| PR | Branch | Finding | Dependency | Status |
|----|--------|---------|------------|--------|
| PR5 | `refactor/standalone-quick-card-first` | Load quick-card first, full standard only on red flag | — | ✅ #45 |
| PR6 | `feat/standalone-metrics-parity` | Metrics for feature/bug-fix/refactor | after PR5 | ✅ #46 |
| PR7 | `feat/standalone-dod-verification` | Verify DoD in final report | after PR6 | ✅ #47 |
| PR8 | `refactor/brainstorm-skip-exception` | Unify "skip questions when context rich" in full-cycle Brainstormer | — | 🟢 open |
| PR9 | `fix/refactor-scope-confirm-order` | Confirm Approved Scope List before `ctl init --scope` | — | ☐ |
| PR10 | `feat/reviewer-diff-standard-mode` | Reviewer reads diff in Standard/CI instead of asking | — | ☐ |
| — | `chore/release-wave-2` | release | — | ☐ |

> PR5→6→7 touch the same standalone SKILL files — keep sequential (rebase).

## Wave 3 — Standards evolution (versioned)

Each new standard: version header, Severity Classification section, register in `standards-quick-card.md`
and `standards/CHANGELOG.md`, and link from the `Rules` of applicable agents.

| PR | Branch | Standard | Status |
|----|--------|----------|--------|
| PR11 | `feat/standard-logging` | `logging.md` | ☐ |
| PR12 | `feat/standard-error-handling` | `error-handling.md` | ☐ |
| PR13 | `feat/standard-concurrency` | `concurrency.md` | ☐ |
| PR14 | `feat/standard-dependencies` | `dependencies.md` | ☐ |
| PR15 | `feat/standard-accessibility` | `accessibility.md` (extract from ui-design §8) | ☐ |
| — | `chore/release-wave-3` | release | ☐ |

## Wave 4 — Major change

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR16 | `refactor/phase-renumber` | Sequential phase numbering (no reserved Phase 4). Major bump. Supersedes PR1/PR2 scheme | ☐ |
| — | `chore/release-major` | major release | ☐ |

---

## Execution order

```
Wave 1 → release → Wave 2 → release → Wave 3 → release → Wave 4 (major)
```
