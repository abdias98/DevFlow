# Escape Analysis — Canonical Pattern

> **Framework-centric principle:** every prior wave improved what the framework can *do* — detect, load, derive, verify. None of them told the framework whether it actually worked, because nothing brought back what happened **after** a cycle was approved. An external reviewer's correction, a QA bug, an incident report — these are the only ground truth for whether the whole chain (Brainstorm → Spec → Plan → Implement → Review) caught what it should have. This document defines how that ground truth gets back into the framework instead of staying in a PR thread nobody revisits.

An **escape** is a defect found *after* a DevFlow cycle reported APPROVED — by a human reviewer, an external tool, a QA pass, or an incident. Recording one is not blame; it is the only measurement that says whether a wave of framework changes actually changed an outcome, as opposed to changing what the framework is instructed to do.

---

## When to Record One

Whenever a defect surfaces in code a DevFlow cycle already approved:

- A comment on a pull request the Reviewer approved.
- A bug found in QA or by a user, traced to a recently-approved cycle.
- An incident whose root cause is in code a DevFlow cycle produced.

Do **not** record: a WARN/INFO finding the Reviewer already reported and the user chose not to act on (that is a decision, not an escape); a request for new functionality (not a defect); a defect in code no DevFlow cycle touched.

---

## Classification

Every escape gets exactly one **class** and exactly one **layer** — the class says *what kind* of defect it was, the layer says *who should have caught it*.

### Class

The six behavioral defect classes from the Correctness & Behavior dimension ([correctness-guide.md](./devflow-review/correctness-guide.md) → Pass 1, Step 2), plus a seventh for defects no standard covered at all:

| Class | Matches |
|---|---|
| `logic` | Inverted condition, wrong boundary, unhandled branch, masking default |
| `state-transitions` | Wrong behavior under a changed input/context, repetition, reordering, missing reset/invalidation |
| `side-effects` | Work performed the wrong number of times, work with no consumer, a resource never released |
| `caller-contract` | A change broke an assumption a consumer relied on |
| `data-limits` | Empty, absent, duplicate, very large, malformed, or out-of-range input mishandled |
| `partial-failure` | A failure partway through left an inconsistent or misleading result |
| `standard-design` | The defect breaks no behavioral class above — it is a design-quality, structural, or standards gap (a rule that doesn't exist, or wasn't applied) |

### Layer

The point in the DevFlow chain that had the information to catch this, had it looked:

| Layer | The escape means... |
|---|---|
| `brainstorm` | The scenario should have been named in `context.md` → Behavior Scenarios, and wasn't |
| `spec` | The scenario was in Behavior Scenarios but didn't reach the State & Interaction Matrix or Standards Applied |
| `plan-tests` | The matrix had it, but no Feature-Level Scenario / task test was derived from it |
| `implementer` | A test existed (or should have, per Discovered During Implementation) and the code still doesn't satisfy it |
| `verifier` | The Verifier's behavior-paths axis should have caught a criterion/scenario with no matching code path, and didn't |
| `reviewer:{dimension}` | A specific Reviewer dimension (e.g. `reviewer:correctness-behavior`, `reviewer:security-safety`) should have found it in its own blind pass |
| `standard-missing` | No standard's domain covers this defect at all — the framework itself has a coverage gap, not a process failure on this cycle |

`standard-missing`, `verifier`, `spec`, `plan-tests` and `reviewer:{dimension}` are **framework layers**: they feed the framework memory ([framework-memory.md](./framework-memory.md)), and through it DevFlow's own standards and skills, rather than only a single cycle's learnings.

---

## Recording an Escape

```bash
devflow-ctl escape add --class <class> --layer <layer> --ref "<PR#/issue/incident>" --note "<one-line description>" [--slug <cycle-slug>]
```

Stored at `docs/devflow/knowledge-base/escapes.md`, one row per escape, in a stable table format `escape list`/`escape report` can parse deterministically.

**Ingestion in Standard/CI mode:** the Finalizer (or a standalone agent's closing step) may **read-only** fetch a PR's comments (`gh pr view {n} --comments`, or the `Artifact` tool's `comments` action for an artifact-hosted review) and propose a classification to the user for each comment that reads as a defect — the user confirms or corrects the class/layer before anything is recorded. **In Pair mode**, the user pastes the comments directly. **The framework never posts to the PR, replies to a comment, or otherwise writes back to the external review** — this is intake only.

---

## What Recording One Does

1. **`docs/devflow/knowledge-base/escapes.md`** gets the row — the permanent record, queryable by `escape list [--layer <layer>]` and summarized by `escape report` (counts by layer and by class).
2. **`learnings.md`** gets an anti-pattern entry (By Topic + Cycle History, same convention as every other knowledge-base write-back) describing what was missed and why, so the *next* cycle in that area doesn't repeat it.
3. **The framework memory counts it** — `escape add` appends the class and layer (no ref, no note) to the cross-project counts in the framework memory store, readable with `devflow-ctl memory escapes` ([framework-memory.md](./framework-memory.md)).
4. **If the layer is a framework layer** — `standard-missing`, `verifier`, `spec`, `plan-tests` or `reviewer:{dimension}` — the lesson belongs to DevFlow, not only to this project, and `escape add` says so. Run `devflow-ctl memory query --type escape`: if an entry already describes the same miss, record the recurrence with `devflow-ctl memory seen <id>`; otherwise record it **in the abstract** with `devflow-ctl memory add --type escape --class <class> --layer <layer> --target <the skill or standard that should have caught it> --key escape:<class>:<layer>:<short-kebab> --title "..." --rule "..."`. The privacy guard refuses the project's paths and names — describe what the layer failed to look for, not the code it missed. Once confirmed in two projects, the entry is promoted into that standard or skill (framework-memory.md → Promotion) — the path Wave 20's audit (`docs/devflow-audit-review-quality.md`) took by hand.

---

## Metrics

`metrics-template.md` → Quality gains:
- **Escapes after APPROVED** — count of escapes recorded against this cycle's slug.
- **Escape layer distribution** — a small table, one row per layer, filled only when non-zero.

`devflow-ctl metrics aggregate` computes an **escape rate** in the Averages section: the fraction of aggregated cycles that have at least one recorded escape. This is the only number in the framework's own metrics that says whether an approved cycle later turned out to have missed something — every other metric describes the cycle's own process, not its outcome.

---

## When This Is Invoked

- **Finalizer** (Phase 8) — asks explicitly: *"Did the previous cycle in this area receive any external correction (a PR review comment, a QA bug, an incident) since it was approved?"* If yes, walks through recording it before closing.
- **Standalone agents** — the same question, asked once per invocation of `/devflow-review` in Standalone Mode when re-invoked after a prior APPROVED in the same area, and at the closing step of Feature/Bug-Fix/Refactor.
- **On demand** — a user can record an escape at any time with `devflow-ctl escape add`, independent of any active session.

---

## Anti-Patterns

- ❌ **Recording a WARN/INFO the user already saw and chose not to act on** — that's a decision, not something the framework missed.
- ❌ **Writing back to the external review** — intake is read-only; the framework never posts, replies, or resolves on someone else's review thread.
- ❌ **Skipping classification "because it's obviously implementer"** — a `verifier` or `reviewer:{dimension}` escape that gets mis-classified as `implementer` hides which layer actually needs to change.
- ❌ **Treating `escapes.md` as a blame log** — it is instrumentation for the framework's own effectiveness, not a record of who to blame for a specific cycle.
