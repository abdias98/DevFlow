# Autonomous Mode — Canonical Pattern

> **Framework-centric principle:** autonomy is orchestrated by the framework, not by the model's ability to "self-sustain." The framework manages persistence, async checkpoints, resume, and escalation. Any model that can follow the lifecycle can operate in autonomous mode — the framework handles the long-duration concerns.

This document defines the canonical pattern for Autonomous Mode — a non-presential execution mode where the user initiates a cycle and leaves, and the framework manages it to completion (or to a genuine human-required BLOCK).

---

## When to Use Autonomous Mode

**Use autonomous mode when ALL of these hold:**
- The task is well-defined (spec + plan exist, or the user's request is clear enough to auto-generate them).
- The environment supports `terminal` (checked via [environment-probe.md](./environment-probe.md)) — autonomous mode requires auto-execution of tests and git.
- The user will be away — they don't want to review each task or approve each step.
- The task is not experimental or high-risk — autonomous mode iterates and debugs, but it won't make architectural decisions without the user.

**Do NOT use autonomous mode when:**
- The task requires architectural decisions that benefit from human review (use the full lifecycle with Pair mode).
- The environment doesn't support `terminal` (autonomous mode requires auto-execution).
- The task is a migration or irreversible operation (use Pair mode with explicit approval at each step).

---

## Activation

- **Environment variable:** `DEVFLOW_AUTONOMOUS=true` activates the mode.
- **Combinable with:** `DEVFLOW_MAX_ITERATIONS=N` (overrides default iteration limits).
- **Detected at:** Orchestrator Step 0, alongside CI mode detection and the environment capability probe.
- **Prerequisite:** `terminal` capability must be `yes` (from [environment-probe.md](./environment-probe.md)). If `terminal` is `no`, autonomous mode is unavailable — inform the user and fall back to Pair mode.

---

## Differences from Other Modes

| Aspect | CI Mode | Standard Mode | Autonomous Mode |
|--------|---------|---------------|-----------------|
| **User presence** | None (pipeline) | Present (convenient) | None (non-presential) |
| **Confirmation Gate** | Auto-approved | User approves | Auto-approved |
| **Spec approval** | Auto-approved | User approves | Auto-approved |
| **Iteration limits** | 1 (fail-fast) | Normal (3) | Normal (3, or `DEVFLOW_MAX_ITERATIONS`) |
| **On test failure** | Exit immediately | Auto-retry → Debugger | Auto-retry → Debugger → escalate to user |
| **On BLOCK** | Exit immediately | Route to user | Write to `send-to-user.md`, pause |
| **Checkpoints** | Pipeline logs | Chat output | `autonomous-log.md` (async, persistent) |
| **Resume** | Pipeline re-run | User resumes | `devflow-ctl status` → resume from last phase |

---

## The Pattern

### 1. Async Checkpoints

After each phase completes, the Orchestrator writes a checkpoint to `docs/devflow/session/{slug}/autonomous-log.md`:

```markdown
## Autonomous Log — {slug}

### {timestamp} — Phase {N}: {phase name}
- **Status:** {completed | failed | escalated}
- **Iterations:** {count}
- **Findings:** {summary — BLOCKs, WARNs, test results}
- **Next:** {what the framework will do next}
- **Artifact:** {path to saved artifact}
```

The log is **append-only** and **does not pause** the cycle. It's for the user to read when they return.

### 2. send-to-user Mechanism

When the framework encounters a genuine BLOCK that requires human input (not auto-resolvable), it writes to `docs/devflow/session/{slug}/send-to-user.md`:

```markdown
## Send to User — {slug}

### {timestamp} — {type}: {title}
- **Type:** {validation-block | iteration-limit | architectural-flaw | deliverable-ready}
- **Phase:** {N}
- **Message:** {what happened and what the user needs to do}
- **Artifact:** {path to relevant artifact}
- **Action needed:** {approve | review | revise | cancel}
```

**When to send to user:**
- Validation Gate BLOCK that can't be auto-resolved (security/architectural issues).
- Iteration limit exceeded (Implementer↔Reviewer or Implementer↔Debugger).
- Architectural flaw discovered mid-implementation requiring redesign.
- Deliverable ready (cycle complete — user should review the final summary).

**When NOT to send to user:**
- Test failures (the Debugger handles them — that's what iterations are for).
- WARN/INFO findings (the Reviewer notes them; the cycle continues).
- Minor deviations (the Implementer's verifier handles them).

### 3. Resume Capability

If the session is interrupted (editor closed, connection lost, etc.):

1. On next invocation, the Orchestrator at Step 0 detects the existing session via `devflow-ctl status`.
2. `devflow-ctl status` shows the current phase, iteration counts, and last checkpoint.
3. The Orchestrator reads `autonomous-log.md` to see what was completed.
4. The Orchestrator reads `phase-state.md` to get the exact phase and gate states.
5. The cycle resumes from the last incomplete phase — completed phases are not re-run.

### 4. Progress Grounding (Obligatory)

Every checkpoint in `autonomous-log.md` MUST be grounded in tool results:
- "Phase 5 complete" is only written if `test-registry.md` shows all tests passing.
- "Phase 6 complete" is only written if the review document exists and has no BLOCK findings.
- "N tasks implemented" is only written if `phase-state.md` shows `[x] Phase 5: Implementer — all N tasks complete`.

This prevents fabricated progress reports — the framework audits its own claims against the persisted state.

### 5. Auto-Approval with Normal Iterations

Unlike CI mode (which auto-approves but fails fast with max 1 iteration), autonomous mode:
- **Auto-approves** the Confirmation Gate and spec approval (the user is away).
- **Uses normal iteration limits** (3 for Implementer↔Reviewer, 3 for Implementer↔Debugger, 2 for Validation→Brainstormer).
- **Iterates and debugs** — if the Implementer's tests fail, the Debugger is invoked. If the Reviewer finds BLOCKs, the Implementer is re-invoked. The cycle persists.
- **Only escalates to the user** when iteration limits are exhausted or a genuine human decision is needed.

---

## Agent Responsibilities in Autonomous Mode

| Agent | Behavior change |
|-------|----------------|
| **Orchestrator** | Detect autonomous mode at Step 0. Auto-approve Confirmation Gate and spec. Write async checkpoints after each phase. Write to `send-to-user.md` on genuine BLOCKs. Resume from last phase on re-invocation. |
| **Brainstormer** | Skip clarifying questions — infer from context or use reasonable defaults. |
| **Architect** | Auto-accept spec without user confirmation. |
| **Planner** | Normal behavior — create plan as usual. |
| **Implementer** | Auto-run tests, commits, branches (like Standard mode). Normal TDD cycle. |
| **Reviewer** | Normal behavior — classify BLOCK/WARN/INFO. |
| **Debugger** | Normal behavior — reproduce, isolate, fix. Iterate up to limit. |
| **Finalizer** | Normal behavior — save summary, clean memory. Write "deliverable ready" to `send-to-user.md`. |

---

## Fallback: No Terminal

If the environment capability probe detects `terminal: no`, autonomous mode is unavailable. The Orchestrator informs the user:

> "Autonomous mode requires terminal execution capability. Your environment does not support it. Falling back to Pair mode (interactive)."

The cycle proceeds in Pair mode — the user must be present to approve commands.

---

## Anti-Patterns

- ❌ **Auto-approve everything** — the Validation Gate is still critical. Auto-approval means the cycle proceeds, but BLOCK findings are still recorded and may trigger escalation if they can't be auto-resolved.
- ❌ **Skip checkpoints** — the async log is the user's only visibility into what happened while they were away. Every phase must be logged.
- ❌ **Fabricate progress** — every checkpoint must be grounded in persisted state (tool results, artifact existence, test-registry). The framework audits its own claims.
- ❌ **Escalate trivial issues** — test failures and WARN findings are handled by iterations, not by escalating to the user. Only escalate genuine human-required BLOCKs.
- ❌ **Re-run completed phases on resume** — the resume capability reads `phase-state.md` and resumes from the last incomplete phase. Completed phases are not re-run.

---

## Agents That Apply This Pattern

| Agent | Application |
|-------|-------------|
| **Orchestrator** (Phase 0) | Detects autonomous mode, manages checkpoints, send-to-user, resume |
| **All lifecycle agents** | Adjust behavior per the table above (skip user interaction, auto-approve) |
