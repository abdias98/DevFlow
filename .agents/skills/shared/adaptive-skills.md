# Adaptive Skills — Canonical Pattern

> **Framework-centric principle:** the level of prescription in a skill should be inverse to the rigor level. At `light`/`standard` rigor, the agent treats numbered steps as objectives + checkpoints and navigates autonomously. At `deep`/`maximum` rigor, the agent follows each step literally. The framework adjusts its own prescriptiveness — it does not detect or route models. Non-negotiable invariants (TDD, scope-lock, gates, artifact validation) are always enforced regardless of rigor level.

This document defines the canonical pattern for adaptive skill prescriptiveness. All lifecycle and standalone agents reference this file to understand how to read their SKILL.md procedure at different rigor levels.

---

## How It Works

The [rigor level](./rules.md) (set by the Planner in Phase 4: `light` | `standard` | `deep` | `maximum`) controls how prescriptive the skill procedures are. This is a **framework-level** adjustment — the framework changes its own scaffolding, not the model's behavior.

### Rigor → Prescriptiveness mapping

| Rigor | Skill reading | Micro-steps | Autonomy | Checkpoints |
|-------|---------------|-------------|----------|-------------|
| **light** | Objectives + acceptance criteria only | Skipped — the agent navigates autonomously | Maximum | Minimal — only at phase boundaries |
| **standard** | Objectives + checkpoints, micro-steps as guides | Treated as guides, not mandates | High — the agent adapts when context is rich | Phase boundaries + on deviation |
| **deep** | Full procedure with all steps | Followed literally, deviations flagged | Moderate — the agent follows the procedure | Phase boundaries + per-task + on deviation |
| **maximum** | Full procedure + extra verification + conservative escalation | Followed literally, no deviations | Low — the agent follows exactly | Phase boundaries + per-task + per-checkpoint + conservative escalation |

### What changes with rigor

**At `light`/`standard` (slim reading):**
- The agent reads the SKILL.md procedure as a **sequence of objectives** (what to achieve) rather than a sequence of commands (what to do).
- Numbered sub-steps are treated as **guides** — the agent can combine, reorder, or skip them if the objective is achieved and the invariants are respected.
- The agent is trusted to navigate ambiguity when the context (plan, spec, knowledge base) is rich.
- The "act when ready" principle ([rules.md](./rules.md) → Progress Honesty & Brevity) is emphasized: when you have enough information to act, act. Do not re-derive established facts or re-litigate user decisions.

**At `deep`/`maximum` (detailed reading):**
- The agent reads the SKILL.md procedure as a **literal sequence of steps** — each step is followed in order.
- Deviations from the procedure are flagged to the user before proceeding (per the Implementer's existing deviation rule).
- Extra verification is applied: more checkpoints, more conservative escalation, more detailed artifacts.
- At `maximum`, the agent escalates more conservatively (e.g., 2 failed attempts instead of 3 before escalating).

### What does NOT change with rigor

**Non-negotiable invariants (always enforced):**
- **TDD Red→Green cycle** — tests before code, always.
- **Scope-locking** — `devflow-ctl scope check` before every file edit, always.
- **Gates** — Validation Gate, Confirmation Gate, artifact validation, always.
- **Progress grounding** — every progress claim audited against tool results, always.
- **Memory persistence** — session memory written at every phase boundary, always.
- **Output format** — the structured response format, always.

These invariants are the floor — they apply at every rigor level. The rigor level adjusts the ceiling (how much scaffolding surrounds the invariants), not the floor.

---

## The Pattern

### 1. Agent reads rigor level at Step 1

Every agent's Step 1 (Load Context) already reads `context.md` and `devflow-ctl status`. The agent also reads the rigor level from `devflow-ctl config get rigor` (or `phase-state.md` frontmatter).

### 2. Agent adapts its reading of the procedure

Based on the rigor level, the agent reads its SKILL.md procedure differently:

- **`light`**: "I will achieve the objectives of each step. I will skip micro-steps that are obvious given the context. I will respect the invariants (TDD, scope-lock, gates). I will checkpoint at phase boundaries."
- **`standard`**: "I will follow the procedure, treating sub-steps as guides. I will combine or adapt steps when the context is rich and the objective is clear. I will respect the invariants. I will checkpoint at phase boundaries and when I deviate."
- **`deep`**: "I will follow the procedure literally, step by step. I will flag deviations before proceeding. I will respect the invariants. I will checkpoint at phase boundaries, per-task, and when I deviate."
- **`maximum`**: "I will follow the procedure literally, step by step, with no deviations. I will apply extra verification at each checkpoint. I will escalate conservatively (2 attempts instead of 3). I will respect the invariants."

### 3. Agent declares its reading mode

At the start of its response, the agent notes its reading mode:

> "Rigor: {level}. Reading procedure as {objectives | guides | literal steps | literal steps + extra verification}."

This makes the adaptation visible to the user — they know what scaffolding is active.

---

## When to Use Each Rigor Level

The Planner (Phase 4) classifies the feature and sets the rigor level. The classification is a **framework decision**, documented in `context.md` and visible to the user:

| Feature type | Default rigor | Rationale |
|--------------|---------------|-----------|
| Trivial (rename, typo, comment) | `light` | Micro-steps are overhead — the agent navigates autonomously |
| Routine (standard CRUD, test writing, simple component) | `standard` | The agent follows guides, adapts when context is rich |
| Complex (new feature, integration, refactoring) | `deep` | The agent follows the procedure literally, flags deviations |
| Frontier (migration, architecture change, novel algorithm) | `maximum` | The agent follows exactly, escalates conservatively, extra verification |

The user can override the Planner's classification at the Confirmation Gate.

---

## Relationship to Other Wave 7 Features

- **Environment capability probe** ([environment-probe.md](./environment-probe.md)): the probe determines what *primitives* are available (subagents, vision, terminal, filesystem). The rigor level determines how *prescriptive* the skills are. They are orthogonal — you can have `deep` rigor in an environment with no subagents (sequential execution, detailed steps) or `light` rigor in an environment with subagents (parallel execution, autonomous navigation).
- **Autonomous mode** ([autonomous-mode.md](./autonomous-mode.md)): autonomous mode uses normal iteration limits. Combined with `light`/`standard` rigor, the agent navigates autonomously while the framework manages persistence. Combined with `deep`/`maximum` rigor, the agent follows the procedure literally while the framework manages the long-duration aspects.

---

## Anti-Patterns

- ❌ **Skip invariants at light rigor** — TDD, scope-lock, gates, and progress grounding are the floor. They apply at every rigor level. "Light" means less scaffolding around the invariants, not no invariants.
- ❌ **Create separate slim skill files** — the adaptation is in how the agent reads the procedure, not in maintaining duplicate files. One SKILL.md serves all rigor levels — the agent reads it differently.
- ❌ **Set maximum rigor for everything** — over-scaffolding degrades capable models. Trust the Planner's classification and the user's override.
- ❌ **Set light rigor for frontier tasks** — under-scaffolding a migration or architecture change is risky. The procedure exists for a reason at high rigor.
- ❌ **Hide the reading mode from the user** — the agent declares its reading mode at the start of its response so the user knows what scaffolding is active.

---

## Agents That Apply This Pattern

| Agent | Application |
|-------|-------------|
| **All lifecycle and standalone agents** | Read the rigor level at Step 1, adapt their reading of the SKILL.md procedure, declare their reading mode. |

See each agent's SKILL.md for the specific procedure. The procedure is the same at all rigor levels — what changes is how the agent reads and follows it.
