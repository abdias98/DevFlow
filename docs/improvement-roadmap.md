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
| PR8 | `refactor/brainstorm-skip-exception` | Unify "skip questions when context rich" in full-cycle Brainstormer | — | ✅ #48 |
| PR9 | `fix/refactor-scope-confirm-order` | Confirm Approved Scope List before `ctl init --scope` | — | ✅ #49 |
| PR10 | `feat/reviewer-diff-standard-mode` | Reviewer reads diff in Standard/CI instead of asking | — | ✅ #50 |
| — | `chore/release-wave-2` | release 2.11.0 | — | 🟢 open |

> PR5→6→7 touch the same standalone SKILL files — keep sequential (rebase).

## Wave 3 — Standards evolution (versioned)

Each new standard: version header, Severity Classification section, register in `standards-quick-card.md`
and `standards/CHANGELOG.md`, and link from the `Rules` of applicable agents.

| PR | Branch | Standard | Status |
|----|--------|----------|--------|
| PR11 | `feat/standard-logging` | `logging.md` | ✅ #52 |
| PR12 | `feat/standard-error-handling` | `error-handling.md` | ✅ #53 |
| PR13 | `feat/standard-concurrency` | `concurrency.md` | ✅ #54 |
| PR14 | `feat/standard-dependencies` | `dependencies.md` | ✅ #55 |
| PR15 | `feat/standard-accessibility` | `accessibility.md` (extracted from ui-design **§10**) | ✅ #56 |
| — | `chore/release-wave-3` | release 2.12.0 | 🟢 open |

## Wave 4 — Major change

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR16 | `refactor/phase-renumber` | Sequential phase numbering (no reserved Phase 4) — Validation→2, Architect→3, Planner→4. Major bump | ✅ #58 |
| — | `chore/release-major` | major release 3.0.0 | 🟢 open |

> **🎉 Roadmap complete.** Waves 1–4 delivered across 16 improvement PRs + 4 releases (2.10.1, 2.11.0, 2.12.0, 3.0.0). Waves 5–7 (Mythos-class) delivered across 15 PRs + 3 releases (3.2.0, 3.3.0, 4.0.0).

---

## Wave 5 — Foundation Mythos (quick wins, bajo riesgo)

| PR | Branch | Feature | Status |
|----|--------|---------|--------|
| #67 | `fix/progress-grounding` | Progress-claim grounding + brevity + act-when-ready rules | ✅ |
| #68 | `fix/reasoning-echo` | Output format `### Reasoning` → `### Summary`, rule 5 reframed | ✅ |
| #69 | `feat/knowledge-base-reads` | Knowledge base reads for Planner/Implementer/Reviewer/Debugger | ✅ |
| #70 | `feat/rigor-adaptativo` | Adaptive rigor level (light/standard/deep/maximum) in devflow-ctl + Planner + Orchestrator | ✅ |
| #71 | `feat/work-packet-format` | Plan template restructured to work packet format | ✅ |
| #72 | `chore/release-3.2.0` | release 3.2.0 | ✅ |

## Wave 6 — Paralelismo + verificación (cambio estructural)

| PR | Branch | Feature | Status |
|----|--------|---------|--------|
| #73 | `feat/parallel-subagents` | `shared/parallel-subagents.md` — patrón canónico | ✅ |
| #74 | `feat/verifier-subagent` | `shared/verifier-subagent.md` + Implementer pre-review verification | ✅ |
| #75 | `feat/architect-parallel-exploration` | Architect parallel codebase exploration (4 subagents) | ✅ |
| #76 | `feat/reviewer-parallel-multi-dimension` | Reviewer parallel multi-dimension review (3 subagents) | ✅ |
| #77 | `feat/implementer-parallel-tasks` | Implementer parallel independent task dispatch (waves) | ✅ |
| #78 | `chore/release-3.3.0` | release 3.3.0 | ✅ |

## Wave 7 — Autonomía + vision + environment probe (major)

| PR | Branch | Feature | Status |
|----|--------|---------|--------|
| #79 | `feat/environment-capability-probe` | `shared/environment-probe.md` + editor profiles `capabilities:` + `devflow-ctl capabilities` + Orchestrator Step 0 probe | ✅ |
| #80 | `feat/autonomous-mode` | `shared/autonomous-mode.md` — non-presential long-duration cycles with async checkpoints, send-to-user, resume | ✅ |
| #81 | `feat/vision-verification` | `shared/vision-verification.md` — visual diff (Reviewer) + screenshot analysis (Debugger) + diagram reading (Architect) | ✅ |
| #82 | `feat/adaptive-skills` | `shared/adaptive-skills.md` — skill prescriptiveness adapts to rigor level | ✅ |
| #83 | `feat/knowledge-base-bootstrap` | Template Agent `bootstrap-knowledge` + `devflow-ctl knowledge list` | ✅ |
| #84 | `chore/release-4.0.0` | release 4.0.0 — Mythos-class major | ✅ |

> **🎉 Mythos-class roadmap complete.** Waves 5–7 delivered across 15 PRs + 3 releases (3.2.0, 3.3.0, 4.0.0). DevFlow is now a framework that extracts maximum potential from any AI: parallelism, autonomy, vision, adaptive prescriptiveness, environment-aware degradation, and cross-cycle learning. Model-agnostic by design.

---

## Execution order

```
Wave 1 → release → Wave 2 → release → Wave 3 → release → Wave 4 (major)
```

---

## Waves 18–21 — Review quality & standards coverage (F65–F96)

> Detailed plan: `docs/implementation-plan-waves-18-21.md` (kept local, not committed — the
> canonical PR-by-PR breakdown). Audit: `docs/devflow-audit-review-quality.md`. Impartiality
> constraint: standards/rules improve by **defect class**, never designed around a specific
> reported bug — see memory `review-improvements-impartial.md`.

### Wave 18 — Review quality (Finding Evidence, Correctness & Behavior dimension, 5-way subagent split)

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR1–PR7 | various | F65–F72: `rules.md` Finding Evidence + Behavioral Impact Severity, `correctness-guide.md`, Reviewer subagent split (up to 5a–5d), eval tasks 003/004 | ✅ #138–#144 |
| PR8 | `chore/release-4.11.0` | release | ✅ #145 → **4.11.0** |

### Wave 19 — Apply upstream (Brainstorm→Plan carry Behavior Scenarios, standards reach every phase)

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR9–PR16 | various | F73–F75, F77, F79–F81, F90, F91: `behavior-scenarios.md`, Design-Time Decisions/Implementation Self-Check on all 16 standards, standards profile, verifier behavior-paths axis | ✅ #146–#153 |
| PR17 | `chore/release-4.12.0` | release | ✅ #154 → **4.12.0** |
| — | baseline run | real `/devflow-feature` executions (tasks 003/004), not just calibration | ✅ #155 |

### Wave 20 — Coverage (4 new standards + behavioral gap audit)

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR18–PR21 | various | F84–F87: `state-lifecycle.md`, `integration-consumption.md`, `data-persistence.md`, `design-patterns.md` (17th–20th standards) | ✅ #156–#159 |
| PR22 | `feat/behavioral-gap-audit` | F88, F89: audit of all 20 standards → 3 real gaps closed (`security.md`, `error-handling.md`, `ui-design.md`) | ✅ #161 (redo of stranded #160) |
| PR23 | `chore/release-4.13.0` | release | ✅ #164 (redo of stranded #162; #163 was a no-op revert, see below) → **4.13.0** |

> **Incident, closed:** #158/#160/#162 landed on a stale intermediate branch instead of `main`
> (GitHub does not retarget a stacked PR's base when the upstream branch merges but isn't
> deleted) despite `gh pr view` reporting `MERGED`. Diagnosed via `git merge-base --is-ancestor`,
> fixed by cherry-picking onto fresh branches off `origin/main` (#161, #164). Root cause closed:
> `delete_branch_on_merge` activated on the repo.

### Wave 21 — Calibration & runtime verification

| PR | Branch | Finding | Status |
|----|--------|---------|--------|
| PR24 | `feat/ctl-escape-analysis` | F92, F93: `escape-analysis.md`, `devflow-ctl escape add\|list\|report`, escape rate in `metrics aggregate` | ✅ #165 |
| PR25 | `feat/runtime-behavior-verification` | F76: `runtime-verification.md`, fifth environment primitive (`runtime`), Reviewer runtime step at deep/maximum rigor | ✅ #166 |
| PR26 | `feat/eval-behavioral-suite` | F94(b): expand to ≥6 behavioral eval tasks across ≥3 project types, `eval/README.md`, `eval/baselines/README.md` comparison table | ⏸ deferred — shipping PR27 first per explicit user instruction; revisit after 4.14.0 |
| PR27 | `chore/release-4.14.0` | release | 🟢 in progress → **4.14.0** |

> **32/32 findings (F65–F96) have at least one PR.** PR26 is the one item shipped after its
> release instead of before — `eval/baselines/4.14.0.md` §2 records why explicitly rather than
> fabricating a comparison the current 2-task suite can't support.
