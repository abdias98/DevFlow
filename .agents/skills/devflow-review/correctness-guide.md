# Correctness & Behavior — Review Guide

> **Framework-centric principle:** the other review dimensions ask *"does this code break a rule?"*. This one asks *"what does this code do when it runs — and is that what it should do?"*. Most defects that reach a human or external PR reviewer break no written rule: an inverted condition, a state that is never reset, work performed twice, a caller whose expectation the change silently breaks. No standard can enumerate them; they have to be found by reasoning about execution.

This is the canonical brief for the **Correctness & Behavior** subagent (subagent 4 of the Reviewer's Step 3). The Reviewer's `SKILL.md` dispatches it; this document defines what it reads, how it reasons, and what it returns. Findings use the evidence forms and severity table defined in [rules.md → Finding Evidence](<{{SKILLS_DIR}}/shared/rules.md>) — this guide does not restate them.

---

## Why two passes

Every other verification layer — Task Supervisor, Verifier, and the Architecture subagent's plan-compliance check — compares the implementation **against the plan**. They are valuable, and they share one failure mode: when the plan never considered a behavior, all of them approve the code consistently. A reviewer that reads the plan first inherits the plan's blind spots.

So this dimension works in two passes:

1. **Blind pass** — reads the code, its consumers and its tests, **without** the spec, the plan or the DoD. It forms its own model of what the code must do from the code's own contracts and callers, and records findings.
2. **Contrast pass** — only then reads the spec, plan and DoD, and classifies each finding. It never uses them to talk itself out of a traced defect.

---

## Pass 1 — Blind

### Reads

| Read | Why |
|------|-----|
| Every changed file, **complete** (not just the diff) | A defect often sits between a changed line and an unchanged one in the same unit |
| **Consumers and direct dependencies** of each changed unit | Contract breaks live in the relationship, not in either file alone |
| Tests that exercise the changed units | Needed for the test-adequacy step |
| Documented behavior the code relies on — doc comments, module headers, README/AGENTS conventions next to the code | These are legitimate sources of "expected" |

**Finding consumers and dependencies**, in order of preference:
1. The plan's File Map → **Impact Zone** table — read the file list only, not the rest of the plan.
2. `devflow-ctl scope impact {file}` when a session exists.
3. A direct search for references to the changed module, exported symbols, routes, events or state keys.

Cap the read at the **direct** consumers and dependencies. Transitive reading is only warranted when a direct consumer re-exports or forwards the changed behavior.

### Does NOT read

The spec, the plan (beyond the Impact Zone file list), `context.md` → Definition of Done, the Implementer's report or reasoning, the Verifier's findings, and the other review subagents' output.

### Procedure

**Step 1 — Behavior inventory.** For each changed unit (function, handler, component, job, query, state container), write down briefly:
- **Inputs** — parameters, request data, events, selections, configuration.
- **State** — what it reads and what it writes, and who else reads or writes the same state.
- **Side effects** — I/O, persistence, network calls, messages/events emitted, subscriptions, timers, caches, anything irreversible or external.
- **Outputs** — return values, responses, rendered or exposed state, errors thrown.
- **Consumers** — who calls or observes it, and what each one assumes (shape, nullability, ordering, timing, error behavior, idempotency).

The inventory is a working note. It is not returned, but every finding must be traceable to it.

**Step 2 — Walk the defect classes.** For each unit, ask the questions below. They are prompts for reasoning, not a checklist to fill in: skip what cannot apply to the unit, and go deeper where the inventory shows state, side effects or asynchrony.

| Class | Questions |
|-------|-----------|
| **Logic** | Is every condition the right way round and complete? Are boundaries inclusive/exclusive as the contract needs? Is there a case the branching does not handle, or a branch that can never be reached? Does a default or fallback silently mask a failure? |
| **State transitions** | Does the result depend on the *sequence* of events, not only the final input? What happens when an input or context changes while earlier work is still in flight? When the same action is repeated? When events arrive in a different order? What state must be reset, invalidated or recomputed when something it derives from changes — and is it? |
| **Side effects** | Is each side effect performed exactly as many times as intended — not duplicated on retry, repetition or re-entry, not skipped on an early return? Is work performed whose result nothing consumes? Is anything started (subscription, timer, listener, connection) without being released when its owner goes away? |
| **Contract with consumers** | Does each consumer in the inventory still get what it assumes: shape, nullability, units, ordering, error type, timing (sync vs async)? Did a rename, a new required field, a changed default or a new exception reach a consumer that was not updated? |
| **Data limits** | Empty, absent, single, many, duplicated, very large, malformed, out-of-range, unknown identifier — which of these can the inputs actually produce, and what happens for each? |
| **Partial failure** | If a step fails halfway, what is left behind — persisted, emitted, displayed or cached? Is the system left in a state the next operation can handle? Does the user or caller see a truthful result? |

Concurrency *hazards on shared state* (locks, atomicity across threads/processes) belong to the Performance & Concurrency subagent. This dimension still owns **sequence** defects inside a single flow — reordering, re-entry, stale results — whether or not threads are involved.

**Step 3 — Trace or drop.** For each suspected defect, trace the concrete path through the code: which input or event, which lines execute, which state changes, what the observer sees. Then:
- **Traced** → write it as a reproducible scenario ([rules.md → Finding Evidence](<{{SKILLS_DIR}}/shared/rules.md>)) and classify it with Behavioral Impact Severity. Where the expected behavior comes from in this pass: the code's own documented contract, the consumer's evident assumption, an existing convention in the codebase, or the test that already asserts it.
- **Plausible but not traceable** (depends on code or runtime behavior you cannot see) → record it as an **open question** with what would have to be true for it to be a defect. Never promote a question to a finding.
- **Not reproducible on inspection** → drop it.

**Step 4 — Test adequacy (mutation reasoning).** For each decision point and side effect in the changed code — a condition, a guard, a reset, an ordering, an `await`, a boundary — imagine the most plausible single mistake: invert it, remove it, move it, off-by-one it. Then ask: *would any existing test fail?*
- If a mutation on a path that matters (a DoD-relevant behavior, a side effect, a state transition, an error path) would survive every test, report a test gap: cite `testing.md §4` and state the surviving mutation and the scenario the missing test should cover.
- If the same path already carries a traced defect from Step 3, fold the test gap into that finding instead of reporting it twice.
- Do not report test gaps for trivial code that `testing.md §4` excludes (plain accessors, generated code, framework wiring).

---

## Pass 2 — Contrast

Now read the spec, the plan and the DoD (cycle mode), or the invoking agent's artifact (standalone mode). Do **not** start new hunting — plan compliance is the Architecture subagent's job. Only classify what Pass 1 found:

| Classification | Condition | Route |
|----------------|-----------|-------|
| **Implementation defect** | The spec/plan/DoD covers the behavior, and the code does not do it | Implementer (cycle) · invoking agent (standalone) |
| **Plan gap** | The spec/plan/DoD never addresses the behavior at all | **Planner** (cycle) · invoking agent, which must amend its plan before fixing (standalone). The finding still counts toward the verdict at its severity: an unplanned defect is still a defect |
| **Deliberate decision** | The spec/plan explicitly decides this behavior (e.g., "duplicate submissions are accepted and deduplicated downstream") | Drop the finding, or keep it as 🟢 INFO citing the decision if the decision itself looks risky |

A plan gap may also **strengthen** a finding: if the DoD states a criterion the traced scenario violates, the expected-behavior source becomes that criterion, and Behavioral Impact Severity treats a failed DoD criterion as BLOCK.

Pass 2 must never downgrade a traced defect merely because the plan did not mention the case. "The plan didn't ask for it" is a plan gap, not a reason to approve.

---

## Output

Returned to the Reviewer for synthesis — the subagent does not write the review document.

```markdown
## Correctness & Behavior — Findings

| # | Severity | Class | File:Line | Scenario | Classification | Suggestion |
|---|----------|-------|-----------|----------|----------------|------------|
| 1 | BLOCK | State transitions | src/x.ext:42 | precondition → sequence → observed {X}, expected {Y} per {source} | Plan gap | {minimal fix + the test that would have caught it} |
| 2 | WARN | Test adequacy | src/y.ext:17 | mutation: removing the guard at :17 survives all tests; untested scenario: {…} (testing.md §4) | Implementation defect | {test to add} |

### Open Questions
- {file:line} — {what would have to be true for this to be a defect; what to check}

### Coverage
- Units inventoried: {N} · Consumers read: {list or "none found — {how searched}"} · Tests read: {list}
```

If nothing is found, say so explicitly and still report Coverage — an empty result with no coverage is indistinguishable from a skipped review.

---

## Sequential Fallback

When subagents are unavailable (`subagents: no` — [environment-probe.md](<{{SKILLS_DIR}}/shared/environment-probe.md>)), the Reviewer performs this dimension inline. The blind pass only means something if the plan has not been read yet, so ordering replaces isolation:

1. Identify changed files from the diff (`git diff --name-only`) or, if the diff is unavailable, from the plan's **File Map section only**.
2. Run **Pass 1 first**, before reading the spec, plan, DoD or invoking agent's artifact. Write the findings down.
3. Only then load the spec/plan/DoD, run the other dimensions, and run Pass 2 on the recorded findings.

Once findings are written, reading the plan cannot silently erase them — Pass 2 has to reclassify each one explicitly.

---

## When This Dimension May Be Skipped

Only when **both** hold, and the skip is stated in the review document with the reason:
- Rigor is `light` ([adaptive-skills.md](<{{SKILLS_DIR}}/shared/adaptive-skills.md>)).
- The diff shows **none** of signals **S1–S4** ([adaptive-skills.md → Objective Diff Signals](<{{SKILLS_DIR}}/shared/adaptive-skills.md>)): no control-flow, state, side-effect or contract change. Typical examples: formatting, comments, documentation, renames confined to one file.

When the Reviewer takes its inline path (skip criteria in Step 3), this dimension is still performed — inline, in the order given by the Sequential Fallback.

---

## Anti-Patterns

- ❌ **Reading the plan first** — the dimension then only finds what the plan already imagined, which the other three layers catch anyway.
- ❌ **Reporting speculation as a finding** — "this might break under load" with no traced path is an open question at most.
- ❌ **Re-flagging rule violations** — a missing auth check or an N+1 query belongs to the dimension that owns that standard. Report it here only if it produces a traced behavioral defect, and synthesis will merge the two.
- ❌ **Style and redesign** — naming, structure and "I would have written it differently" are not behavior. A finding needs an observable wrong outcome.
- ❌ **Reviewing only the diff hunks** — the defect is frequently the unchanged line next to the changed one, or the consumer that was not changed at all.
- ❌ **Letting the plan excuse a defect** — an unplanned behavior that is observably wrong is a plan gap *and* a finding.
- ❌ **Unbounded exploration** — direct consumers and dependencies only, unless a direct consumer forwards the changed behavior.
