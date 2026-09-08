# Metrics Template

Metrics are recorded per cycle and saved to `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md`. An aggregate file `docs/devflow/metrics/_aggregate.md` tracks cross-cycle trends.

**Contract artifact:** `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md`
**Initialized by:** Orchestrator (Step 0 — creates empty metrics stub)
**Updated by:** Orchestrator (phase completions — timing + iteration counts)
**Finalized by:** Finalizer (quality metrics + aggregate update)

**Standalone agents** (Feature, Bug-Fix, Refactor) create and finalize their own lightweight metrics file — see *Standalone Agent Metrics Format* below — and append to the same `_aggregate.md`.

## Per-Cycle Metrics Format

```markdown
# DevFlow Metrics — {slug}

**Cycle started:** {ISO timestamp}
**Cycle completed:** {ISO timestamp}
**Feature:** {slug}
**Stack:** {Language} · {Framework} · {Test Runner}
**Stack Mode:** {yes/no}

## Timing

| Phase | Started | Completed | Duration (min) |
|-------|---------|-----------|:--------------:|
| Phase 1: Brainstormer | {ts} | {ts} | {N} |
| Phase 2: Validation Gate | {ts} | {ts} | {N} |
| Phase 3: Architect | {ts} | {ts} | {N} |
| Phase 4: Planner | {ts} | {ts} | {N} |
| Phase 5: Implementer | {ts} | {ts} | {N} |
| Phase 6: Reviewer | {ts} | {ts} | {N} |
| Phase 7: Debugger | {ts} or "—" | {ts} or "—" | {N} or "—" |
| Phase 8: Finalizer | {ts} | {ts} | {N} |
| **TOTAL** | **{ts}** | **{ts}** | **{N}** |

## Iterations

| Loop | Phases | Count | Max |
|------|--------|:----:|:---:|
| Validation Gate → Brainstormer | 2 ↔ 1 | {N} | 2 |
| Implementer ↔ Reviewer | 5 ↔ 6 | {N} | 3 |
| Implementer ↔ Debugger | 5 ↔ 7 | {N} | 3 |
| Planner revision | 4 ↔ 4 | {N} | 2 |

## Quality

| Metric | Value |
|--------|-------|
| BLOCK findings | {N} |
| WARN findings | {N} |
| INFO findings | {N} |
| Tests created | {N} |
| Tests passing (first run) | {N}/{N} ({N}%) |
| DoD criteria met | {N}/{N} ({N}%) |
| Traceability coverage | {N}% |
| Rollbacks performed | {N} |

## Reviewer Categories

| Severity | Top Categories |
|----------|----------------|
| 🔴 BLOCK | {e.g., "Missing validation (2), Hardcoded secret (1)"} |
| 🟡 WARN | {e.g., "Naming inconsistency (3), Missing memoization (1)"} |
| 🟢 INFO | {e.g., "Code smell in unrelated file (2)"} |

## Notes

{Any cycle-specific observations, anomalies, or lessons learned}
```

## Aggregate Metrics Format

`docs/devflow/metrics/_aggregate.md` is appended by the Finalizer after each cycle:

```markdown
# DevFlow Aggregate Metrics

> Updated: {ISO timestamp}

## Cycle History

| # | Date | Type | Feature | Duration | Tasks | BLOCKs | Test Pass % | Iterations |
|---|------|------|---------|:--------:|:-----:|:------:|:----------:|:----------:|
| 1 | {date} | full | {slug} | {min} | {N} | {N} | {N}% | {N} |
| 2 | {date} | feature | {slug} | {min} | {tests} | {N} | — | {N} |

> **Type** = `full` (lifecycle cycle) or the standalone agent: `feature`, `bug-fix`, `refactor`. For standalone rows, **Tasks** = tests created and **Test Pass %** = `—` (standalone agents do not run tests).

## Averages (last {N} cycles)

| Metric | Value |
|--------|-------|
| Avg. cycle duration | {N} min |
| Avg. BLOCKs per cycle | {N} |
| Avg. test pass rate (first run) | {N}% |
| Most frequent BLOCK category | {category} |
| Phase with most retries | {phase} |
| Total cycles completed | {N} |
```

## Standalone Agent Metrics Format

Standalone agents (Feature, Bug-Fix, Refactor) record a **lightweight** metrics file at `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` (same path and aggregate as the cycle). They have no multi-phase timing — only start/end and quality.

```markdown
# DevFlow Metrics — {slug} (standalone: {feature|bug-fix|refactor})

**Started:** {ISO timestamp}
**Completed:** {ISO timestamp}
**Agent:** {Feature Agent | Bug-Fixer | Refactorer}
**Stack:** {Language} · {Framework} · {Test Runner}

## Quality

| Metric | Value |
|--------|-------|
| Files created | {N} |
| Files modified | {N} |
| Tests created | {N} |
| BLOCK findings (Reviewer) | {N} |
| WARN findings (Reviewer) | {N} |
| INFO findings (Reviewer) | {N} |
| Reviewer iterations | {N} |
| Scope additions (`scope add`) | {N} |

## Notes

{Any run-specific observations}
```

## Generation Rules

### Orchestrator (Step 0)
1. Create `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` with the cycle header (slug, stack, started timestamp).
2. Leave all metric values empty (filled incrementally).

### Orchestrator (each phase completion)
1. Record phase start/end timestamps in the Timing table.
2. Increment iteration counters when loops occur.

### Finalizer (Step 3 — Collect Artifacts)
1. Read the review document from `docs/devflow/reviews/` → count BLOCK/WARN/INFO, extract top categories.
2. Read `test-registry.md` → count tests created, first-pass rate.
3. Read `context.md` → count DoD criteria, met/unmet.
4. Run `devflow-ctl traceability check traceability.md` → coverage percentage (do not count rows yourself).
5. Fill all remaining metric values.
6. Save the completed metrics file.

### Finalizer (after metrics saved)
1. Run `devflow-ctl metrics aggregate docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md`. This appends the row to `_aggregate.md` (creating the file if missing, with `Type = full` read from the metrics file's own header) and recomputes the 4 Averages rows that have a real column behind them (avg. cycle duration, avg. BLOCKs per cycle, avg. test pass rate, total cycles completed) — deterministically, not by reading the table yourself.
2. "Most frequent BLOCK category" and "Phase with most retries" have no structured column in Cycle History to derive from; the command leaves them untouched (a manual entry on the first row, or whatever was there before). Update them yourself only if you have something concrete to add for this cycle.

### Standalone agents (Feature / Bug-Fix / Refactor)
1. **At session init** (right after `devflow-ctl init`): create `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` using the *Standalone Agent Metrics Format* with the header `# DevFlow Metrics — {slug} (standalone: {feature|bug-fix|refactor})` (slug, agent, stack, started timestamp). Leave quality values empty.
2. **After the auto-invoked Reviewer returns:** fill files created/modified, tests created, the Reviewer's BLOCK/WARN/INFO counts, Reviewer iterations, and scope additions (`scope add` count); set the completed timestamp. Save the file.
3. Run `devflow-ctl metrics aggregate docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` — it reads the `(standalone: {type})` suffix from the header to set `Type` in the new row automatically (Tasks = tests created, Test Pass % = `—`, Iterations = Reviewer loops), and recomputes averages the same way the Finalizer does.
