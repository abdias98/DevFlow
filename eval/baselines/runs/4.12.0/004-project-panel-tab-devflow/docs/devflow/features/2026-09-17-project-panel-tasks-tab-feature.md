# Feature Report: Project panel Tasks tab

**Date:** 2026-09-17
**Agent:** DevFlow Feature Agent ⚡
**Stack:** JavaScript (Node CommonJS) · none (framework-free state layer)

## Summary

**Goal:** Add a `tasks` tab to the panel, loaded via `api.getTasks(projectId)`, following the Overview tab's `{status,data,error}` shape.

## Definition of Done

| # | Criterion | Met? | Evidence |
|---|-----------|:----:|----------|
| 1 | `selectTab('tasks')` shows the selected project's tasks in `getState().tasks` | ✅ | `opening the Tasks tab loads the selected project tasks` |
| 2 | `tasks` has loading/error states like `overview` | ✅ | shared `load(tab)` helper drives both slices identically |
| 3 | The panel never shows data belonging to a project other than the current selection | ✅ | `a late response for a superseded project selection is discarded (Overview)`, `switching project while on the Tasks tab never mixes tasks across projects` |
| 4 | Overview keeps working | ✅ | pre-existing 4 Overview tests still pass unmodified |
| 5 | Covered by tests | ✅ | 6 new tests, 10/10 passing |

**Result:** 5/5 criteria met.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/panel.js` | Modified | Replaced the ad hoc `loadOverview`/`loadActiveTab` pattern with a shared `load(tab)` helper that tags every request with a token and discards a response if a newer request for that tab has since started; `tasks` uses the same helper |
| `test/panel.test.js` | Modified | 6 new tests: Overview late-response discard, Overview error-after-switch, Tasks happy path, Tasks-before-project edge case, Tasks failure, Tasks project-switch-mid-load |

## Tasks Completed

- [x] Task 1: Shared stale-response-safe loader (fixes a latent gap in the Overview tab's existing pattern)
- [x] Task 2: Tasks tab wired onto the shared loader (no additional production code needed — the loader was already generic)

## Tests

| Test File | Test Name | Status |
|-----------|-----------|--------|
| `test/panel.test.js` | `a late response for a superseded project selection is discarded (Overview)` (S1) | ✅ Passing |
| `test/panel.test.js` | `an error for the new selection does not leave the previous selection's data (Overview)` (S3) | ✅ Passing |
| `test/panel.test.js` | `opening the Tasks tab loads the selected project tasks` | ✅ Passing |
| `test/panel.test.js` | `selecting the Tasks tab before a project is selected does nothing yet` | ✅ Passing |
| `test/panel.test.js` | `a failed tasks request surfaces an error state` | ✅ Passing |
| `test/panel.test.js` | `switching project while on the Tasks tab never mixes tasks across projects` (S2) | ✅ Passing |

**Verify with:**
- Single file: `node --test test/panel.test.js`
- Full suite: `npm test`

## Self-Review

| Check | Result |
|-------|--------|
| Security | ✅ no external input beyond already-guarded `projectId`/tab name |
| Naming conventions | ✅ `load`/`loaders`/`TABS` follow the existing module's naming |
| SOLID principles | ✅ single loader function serves every tab — no per-tab duplication |
| Test coverage | ✅ happy path, edge case, failure, and a sequence test per Behavior Scenario |

## Notes

The prompt said "follow the conventions of the Overview tab." Deriving Behavior Scenarios from the framework's Transition Prompts (Step 1, before any code was written) surfaced that the Overview convention itself has a gap: it does not tie a response to the request that produced it, so a response for a project the user has since navigated away from can overwrite the current selection's state. Copying that convention faithfully would have copied the gap into Tasks. Instead, Task 1 replaces the shared pattern with a token-based "latest request wins" loader, fixing Overview as a declared Impact Zone change (justified in the plan's Standards constraints — `design-principles.md §1`, one loader instead of two copies of the same flawed logic) and building Tasks on the corrected version. No BLOCK findings from the Reviewer.
