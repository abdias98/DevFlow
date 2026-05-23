# Performance Report Template

Save to `docs/devflow/performance/YYYY-MM-DD-{slug}-perf.md`:

```markdown
# Performance Report: {Title}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Performance Agent ⚡
**Stack:** {Language} · {Framework}
**Target:** {file, function, endpoint, or module}

## Summary

**Symptom:** {one-line description of the performance issue}
**Root bottleneck:** {file}:{line} — {cause}

## Static Analysis Findings

| # | Severity | File:Line | Anti-Pattern | Impact | Recommendation |
|---|----------|-----------|-------------|--------|----------------|
| 1 | 🔴 | `auth.ts:42` | N+1 query | +200ms per request | Eager load `roles` relation |
| 2 | 🟡 | `parser.ts:88` | O(n²) loop | +50ms for n>100 | Use Map for lookup |
| 3 | 🟢 | `config.ts:12` | Uncached config read | +5ms | Memoize or cache |

## Benchmark Results

### Baseline
```
{paste benchmark output or "No baseline available — first measurement"}
```

### Current
```
{paste benchmark output after analysis}
```

### Comparison

| Metric | Baseline | Current | Delta | Status |
|--------|:--------:|:-------:|:-----:|:------:|
| Avg response time | {N}ms | {N}ms | {±N}% | ✅/🔴 |
| P95 latency | {N}ms | {N}ms | {±N}% | ✅/🔴 |
| Throughput | {N} req/s | {N} req/s | {±N}% | ✅/🔴 |
| Memory (peak) | {N}MB | {N}MB | {±N}% | ✅/🔴 |

## Recommendations

### High Priority (🔴)
1. **{Title}** — `{file}:{line}`
   - **Change:** {description}
   - **Estimated impact:** {metric} improves by {N}%
   - **Risk:** {low/medium/high}

### Medium Priority (🟡)
2. **{Title}** — `{file}:{line}`

### Low Priority (🟢)
3. **{Title}** — `{file}:{line}`

## Benchmark Setup

**Command to reproduce:**
```bash
{exact benchmark/profiling command}
```

**New benchmark file (if created):**
- `{path}` — {description}

## Notes

{Any context, trade-offs, or follow-up recommendations}
```
