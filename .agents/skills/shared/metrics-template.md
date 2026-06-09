# Metrics Template

Metrics are recorded per cycle and saved to `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md`. An aggregate file `docs/devflow/metrics/_aggregate.md` tracks cross-cycle trends.

**Initialized by:** Orchestrator (Step 0 — creates empty metrics stub)
**Updated by:** Orchestrator (phase completions — timing + iteration counts)
**Finalized by:** Finalizer (quality metrics + aggregate update)

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
| Phase 1.5: Validation Gate | {ts} | {ts} | {N} |
| Phase 2: Architect | {ts} | {ts} | {N} |
| Phase 3: Planner | {ts} | {ts} | {N} |
| Phase 5: Implementer | {ts} | {ts} | {N} |
| Phase 6: Reviewer | {ts} | {ts} | {N} |
| Phase 7: Debugger | {ts} or "—" | {ts} or "—" | {N} or "—" |
| Phase 8: Finalizer | {ts} | {ts} | {N} |
| **TOTAL** | **{ts}** | **{ts}** | **{N}** |

## Iterations

| Loop | Phases | Count | Max |
|------|--------|:----:|:---:|
| Validation Gate → Brainstormer | 1.5 ↔ 1 | {N} | 2 |
| Implementer ↔ Reviewer | 5 ↔ 6 | {N} | 3 |
| Implementer ↔ Debugger | 5 ↔ 7 | {N} | 3 |
| Planner revision | 3 ↔ 3 | {N} | 2 |

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

| # | Date | Feature | Duration | Tasks | BLOCKs | Test Pass % | Iterations |
|---|------|---------|:--------:|:-----:|:------:|:----------:|:----------:|
| 1 | {date} | {slug} | {min} | {N} | {N} | {N}% | {N} |
| 2 | {date} | {slug} | {min} | {N} | {N} | {N}% | {N} |

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
4. Read `traceability.md` → coverage percentage.
5. Fill all remaining metric values.
6. Save the completed metrics file.

### Finalizer (after metrics saved)
1. Read `docs/devflow/metrics/_aggregate.md` (create if missing).
2. Append a new row to the Cycle History table.
3. Recalculate averages across all cycles.
