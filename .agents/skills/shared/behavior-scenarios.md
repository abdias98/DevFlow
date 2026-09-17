# Behavior Scenarios — Canonical Pattern

> **Framework-centric principle:** with TDD, code does what its tests describe — and nothing more. A behavior no test describes is not merely untested: the Implementer is told to write the minimal code that passes, so the behavior is, by construction, not handled. Edge cases phrased as *inputs* ("empty", "invalid") miss the defects that live in *sequences*: something changes while work is in flight, an action is repeated, results arrive out of order, a step fails after another succeeded. Those have to be derived on purpose, before the tests are written.

This document defines how behavior scenarios are discovered, recorded and turned into tests across the lifecycle. Templates and skills reference it instead of restating it.

---

## The Chain

| Phase | Artifact | What it adds |
|-------|----------|--------------|
| **Brainstormer** (or Feature Agent Step 1) | `context.md` → `## Behavior Scenarios` | Transitions the *request* implies, in the user's terms — no design |
| **Architect** | spec → `### State & Interaction Matrix` | For every stateful unit: states × events → expected result, each row traced to its source |
| **Planner** (or Feature Agent plan) | plan → `## Feature-Level Scenarios` | Each matrix row becomes at least one Given/When/Then scenario with an owning task and a test |
| **Planner** | `traceability.md` | One `Behavior Scenario` row per scenario, so coverage is counted, not assumed |
| **Implementer** | tests | Scenario tests are written Red first, like any other test |
| **Reviewer** | review | Correctness & Behavior checks the scenarios the code *should* satisfy, including ones the plan missed (plan gap) |

A scenario may be discovered late — by the Implementer, the Verifier or the Reviewer. It is still recorded in the plan and traceability, so the next cycle in that area starts with it.

---

## Transition Prompts

Use these to discover scenarios. They are prompts for thinking, not a form to fill: ask only what the feature can actually exhibit, and record only what has an expected outcome someone can state.

| Prompt | Ask |
|--------|-----|
| **Change while in flight** | What if the input, selection, context or configuration changes while earlier work for the previous value is still running? |
| **Repetition** | What if the same action happens twice — double submit, retry, re-open, re-select the same value? |
| **Order** | What if events, responses or messages arrive in a different order than they were sent? |
| **Interruption** | What if the user leaves, cancels, closes, navigates away, or the process stops halfway? |
| **Partial failure** | What if one step fails after another already succeeded? What is left visible or persisted? |
| **Reset vs keep** | When the context changes, which state must reset, which must persist, and which must be recomputed? |
| **Other actors** | What if another user, tab, device, job or process acts on the same thing at the same time? |
| **Boundaries of lifecycle** | First use, empty state, last item removed, limit reached, session expired. |

---

## State & Interaction Matrix (spec)

**Required** for every stateful unit the design adds or changes: a UI component or view with state, a service or store that holds state, a workflow or state machine, a job, a consumer, a cache. One table per unit, or one table with a *Unit* column.

```markdown
### State & Interaction Matrix

| # | Unit | State (before) | Event | Expected result | Source |
|---|------|----------------|-------|-----------------|--------|
| M1 | {unit} | {state} | {event or sequence} | {observable outcome, including what resets and what does not} | DoD 2 / Edge Case 3 / Behavior Scenario 1 / Spec §{…} / existing convention `{path}` |
```

- **Expected result** is observable (what a user, caller or persisted record shows), not an implementation step.
- **Source** names where the expectation comes from. A row with no source is a design decision — record it under Design Decisions and cite that.
- Cover, at minimum: the normal transitions, and every Transition Prompt above that the unit can exhibit.
- **No stateful unit** → write exactly: `N/A — stateless: {one-line reason}`. An empty section is not N/A.

---

## Feature-Level Scenarios (plan)

**Required** in every plan. Unit tests per task stay; these are the tests that exercise *sequences and interactions* across calls, units or events.

```markdown
## Feature-Level Scenarios

| # | Given | When | Then | Matrix row | Task | Test file |
|---|-------|------|------|------------|------|-----------|
| S1 | {precondition} | {event sequence} | {observable outcome} | M1 | Task N | `path` |
```

- Every non-N/A matrix row maps to **at least one** scenario.
- Each scenario is owned by a task, and its test code appears in that task's `🧪 Tests for this Task` section under a `🔁 Sequence / interaction scenario` marker, written to fail first.
- A scenario test drives the unit through the **sequence** (select A, then B; send, then send again; fail step 2 after step 1) and asserts the final observable outcome — not internal calls.
- Spec matrix `N/A` → plan section `N/A — stateless (spec)`. A spec with a real matrix and a plan with N/A scenarios fails `devflow-ctl artifacts check plan --spec`.

---

## Discovered During Implementation

"Write minimal code" and "never add features not in the plan" protect scope. Read literally, they also forbid handling a case the plan forgot — and an Implementer that obeys leaves a defect in place without saying anything. The two situations are different, and are handled differently:

| | **New functionality** | **A missing case of requested behavior** |
|---|---|---|
| **What it is** | A capability, option, output, endpoint or UI element nobody asked for | The behavior that *was* asked for is observably wrong in a situation it can actually reach — one of the Transition Prompts, a data limit, a failure path |
| **The question** | "Is this something the request did not ask for?" | "Would the person who asked for this feature call the current behavior in this situation a bug?" |
| **Generic example** | Adding an export button to a list view because it seemed useful | Submitting a form twice while the first submission is still in progress creates two records, because the plan only tested a single submit |
| **Rule** | **Prohibited.** Record it in `### Additional Recommendations`; do not build it | **Required.** Handle it — through a test, never silently |

**Procedure for a missing case:**

1. **State it as a scenario** — Given / When / Then, observable outcome, and the source of the expectation (the requirement it belongs to).
2. **Red first** — add the sequence test to the owning task's test file and confirm it fails for the right reason (`testing.md §9`). In Pair mode, inform the user exactly as for any other test.
3. **Minimal Green** — the smallest change that makes the new test pass, within the task's declared files. If the fix needs a file outside them, the normal scope rules apply (`rules.md` → Scope-Locking — Three Zones): an Impact Zone file with a closed coherence reason is justified with `devflow-ctl scope justify`; anything else stops and asks.
4. **Record it where the next reader will look:**
   - the plan's `## Feature-Level Scenarios` (or the Feature Agent plan's `### Behavior Scenarios`) gains the row, marked `(discovered)`;
   - `traceability.md` gains a row with Source `Behavior Scenario (discovered)` — `traceability check` reports it as its own source, so discovered cases stay visible in the coverage summary;
   - `### Additional Recommendations` names it as a **plan gap**, so the Reviewer and the Finalizer see that the plan missed it.

No prior user approval is needed for a missing case that stays within the task's declared files — the user approved the behavior; this makes it true. Approval **is** needed for new functionality, and for any scope expansion.

---

## Anti-Patterns

- ❌ **Inputs only** — "empty list, invalid id, null" and nothing about sequences. Input edge cases are necessary, not sufficient.
- ❌ **Implementation in the Brainstorm** — scenarios at that stage describe what the user observes, never how it is built.
- ❌ **Matrix rows without sources** — an expectation nobody asked for is a design decision; record it as one.
- ❌ **Scenario tests that assert internals** — "calls fetch once" instead of "shows only B's data"; assert the observable outcome, and assert call counts only when the count *is* the requirement (e.g., "charges once").
- ❌ **Every prompt for every unit** — a stateless formatter has no "change while in flight". Ask what can happen.
- ❌ **Leaving a late-discovered scenario out of the plan** — record it (plan + traceability) even if it was found in review.
- ❌ **"It wasn't in the plan"** as the reason a reachable wrong behavior was left in place — that is a missing case, and it is required.
- ❌ **Fixing a missing case silently** — no test, no record: the next change breaks it again and nobody knows the plan had a gap.

---

## Agents That Apply This Pattern

| Agent | Application |
|-------|-------------|
| **Brainstormer** | Transitions & Lifecycle category; `## Behavior Scenarios` in the Understanding Summary and `context.md` |
| **Architect** | `### State & Interaction Matrix` in the spec |
| **Planner** | Derives `## Feature-Level Scenarios`; scenario tests in the owning task; `Behavior Scenario` rows in `traceability.md` |
| **Feature Agent** | Transitions & Lifecycle questions; `### Behavior Scenarios` in its plan with owning task and test; handles missing cases found while implementing |
| **Implementer** | Handles missing cases found while implementing (Discovered During Implementation), recording each as `(discovered)` |
