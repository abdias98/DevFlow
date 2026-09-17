# Code Review: Project panel Tasks tab

**Date:** 2026-09-17
**Reviewer:** DevFlow Reviewer (automated)
**Review Mode:** Standalone (invoked by Feature Agent)
**Reference:** `docs/devflow/features/2026-09-17-project-panel-tasks-tab-feature-plan.md`

## Summary
Tasks tab added on a new shared `load(tab)` helper that discards responses superseded by a later request; this replaces Overview's ad hoc pattern, which had the same latent gap. No blockers.

## Findings

> **Evidence** is `{standard}.md §{N}` or `scenario: {precondition} → {sequence} → observed {X}, expected {Y} per {source}` — see rules.md → Finding Evidence.

### 🔴 BLOCK (must fix)
| # | File | Line | Issue | Evidence | Suggestion |
| — | — | — | None | — | — |

### 🟡 WARN (should fix)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `src/panel.js` | `selectProject` | Invalidating `latestRequest` for every tab on every project switch means a tab that was mid-load and is *not* the active tab still has its in-flight promise running (though its result will be discarded) — a wasted network call | `performance.md §4` (INFO-adjacent; kept as WARN because it's a change from the prior single-active-load behavior, worth a deliberate note) | Optional: also let `load()` check `state.projectId` at apply-time to short-circuit, or leave as-is since the discard already prevents an incorrect UI outcome |

### 🟢 INFO (optional)
| # | File | Line | Issue | Evidence | Suggestion |
|---|------|------|-------|----------|------------|
| 1 | `src/panel.js` | `load` | Errors from a discarded (superseded) request are swallowed with no logging hook | `error-handling.md §2` (not a blocker — this is a pure state layer with no logging port injected) | If a logging port is added to this module later, log discarded-request errors at debug level |

### ❓ Open Questions
- None.

## Coverage

| Dimension | Ran? | Standards loaded in full | Notes |
|-----------|------|--------------------------|-------|
| 1 — Security & Safety | ✅ | `security.md`, `error-handling.md` | No external input beyond `projectId`/tab name, both already guarded (`selectTab` throws on an unknown name) |
| 2 — Performance & Concurrency | ✅ | `performance.md`, `concurrency.md` | Token-based discard reviewed against `concurrency.md §5` (idempotency/redelivery) — applies cleanly to client-side async state, not just server redelivery |
| 3 — Architecture & Design | ✅ | `design-principles.md`, `solid.md`, `project-design.md`, `testing.md` | Consistency check against the *stated* reference (Overview's old pattern) found the reference itself defective (per plan's Behavior Scenarios) — the plan's decision to fix the shared pattern rather than copy the defect is the correct call per `design-principles.md §1` (DRY: one loader, not two copies of the same logic) |
| 4 — Correctness & Behavior | ✅ (blind pass performed) | — | Consumers read: none outside this module — `panel.js` has no other internal callers, and no view/DOM code exists yet in this codebase. Scenarios walked: 7 (Tasks happy path, tab-before-project edge case, Tasks failure, Overview late-response-discarded, Overview error-after-switch, Tasks project-switch-mid-load, existing pre-change Overview tests). Mutation check: removing the `latestRequest[tab] !== token` guard would be caught by the S1 and S2 tests; removing the per-tab reset in `selectProject` would be caught by S2. Open questions: 0 |
| 5a — Interfaces | ⏭ no trigger | — | No HTTP/event surface changed — `api.js` untouched |
| 5b — Presentation | ⏭ no trigger | — | No UI/DOM code in this module |
| 5c — Operations | ⏭ no trigger | — | No logging/dependency changes |

- **Review path:** inline (2 files) — Correctness & Behavior still ran per policy.
- **Diff signals present:** S1 (control flow — token comparison), S2 (state — per-tab slices), S4 (contract — `loadOverview`/ad hoc pattern replaced by `load(tab)`, but `getState()` shape for `overview` is unchanged so no consumer breaks)
- **Deterministic checks:** `scan all` → clean · `scope audit` → n/a (no Impact Zone files outside `src/panel.js`/`test/panel.test.js`, both declared Core) · `traceability check` → n/a (standalone mode)
- **Visual diff:** skipped — no UI, no vision needed
- **Not covered:** a real DOM/view layer consuming this state (none exists in the fixture yet)

## Verdict
✅ APPROVED — no blockers
