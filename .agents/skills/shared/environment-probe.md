# Environment Capability Probe — Canonical Pattern

> **Framework-centric principle:** DevFlow does not detect or route models. What DevFlow *does* detect is whether the **environment** (editor + tools available) supports the primitives its features need: subagent invocation, vision tools, terminal/bash, persistent filesystem. This detection is of *environment capabilities*, not model capabilities. When a primitive is unavailable, the framework degrades gracefully to the equivalent sequential/manual/code-only mode — the cycle never breaks.

This document defines the canonical pattern for probing environment capabilities at cycle start and degrading gracefully when primitives are missing. The Orchestrator (Phase 0) and all agents that use environment-dependent features reference this file.

---

## The Four Primitives

| Primitive | What it means | Features that depend on it | Fallback when absent |
|-----------|---------------|---------------------------|---------------------|
| **subagents** | The editor can dispatch subagents (parallel or sequential sub-task invocation) | Parallel exploration (Architect), parallel review (Reviewer), parallel tasks (Implementer), verifier subagent | Sequential execution — the orchestrating agent runs subtasks inline (see [parallel-subagents.md](./parallel-subagents.md) → Fallback) |
| **vision** | The editor has tools that can read images/screenshots | Visual verification (Reviewer visual diff, Debugger screenshot analysis) | Code-only review — no visual diff, no screenshot debugging (see [vision-verification.md](./vision-verification.md) when available) |
| **terminal** | The editor can execute bash/shell commands | Standard mode (auto-execute tests/git), CI mode, Autonomous mode | Pair mode forced — the agent tells the user each command and waits for confirmation (see [rules.md](./rules.md) → Implementation Modes) |
| **filesystem** | The editor has a persistent writable filesystem | Knowledge base, session memory, persistent artifacts, `devflow-ctl` state | No DevFlow cycle — filesystem is a hard prerequisite. If unavailable, the Orchestrator stops and informs the user. |

---

## How the Probe Works

### 1. Declaration (editor profiles)

Each `editor-profiles/*.yaml` declares a `capabilities:` section:

```yaml
capabilities:
  subagents: true
  vision: false
  terminal: true
  filesystem: true
```

The profile author knows what the editor supports. This is a **static declaration**, not runtime detection.

### 2. Recording (install time)

`install.sh` reads the active profile's `capabilities:` section and writes a `.devflow-environment` marker file to the shared directory during installation. This file is a simple key-value store:

```
profile: opencode
subagents: true
vision: true
terminal: true
filesystem: true
```

### 3. Reading (runtime)

`devflow-ctl capabilities` reads the marker file and prints the capabilities. `devflow-ctl capabilities get <key>` prints a specific capability. If the marker file does not exist (e.g., running from the repo without installing), all capabilities default to `unknown` — the Orchestrator asks the user or assumes conservative defaults.

### 4. Recording in session memory

The Orchestrator at Step 0 (Session Initialization) runs `devflow-ctl capabilities` and records the results in `context.md` under `## Environment Capabilities`:

```markdown
## Environment Capabilities

| Primitive | Available | Impact |
|-----------|-----------|--------|
| subagents | yes | Parallel exploration, review, and task dispatch active |
| vision | no | Code-only review (no visual diff) |
| terminal | yes | Standard/CI/Autonomous modes available |
| filesystem | yes | Knowledge base, session memory, persistent artifacts active |
```

All downstream agents read this section to know what features are active.

---

## Graceful Degradation

When a primitive is unavailable, the framework degrades — it never breaks:

### No subagents

- **Architect**: exploration runs sequentially (sub-steps 1→8 in order, no parallel dispatch).
- **Reviewer**: review runs inline (single pass through the checklist, no parallel multi-dimension dispatch).
- **Implementer**: tasks run sequentially (standard TDD procedure, no parallel wave dispatch).
- **Verifier**: the Implementer performs inline verification with a deliberate context reset (see [verifier-subagent.md](./verifier-subagent.md) → Fallback).

The synthesis step is identical — only the execution order changes. The framework's output is the same quality; it just takes longer.

### No vision

- **Reviewer**: no visual diff sub-step for UI features. The review is code-only (checks design tokens, accessibility attributes, layout code — but does not compare rendered UI against mockup).
- **Debugger**: no screenshot analysis. Debugging relies on logs, stack traces, and code inspection only.

### No terminal

- **Pair mode forced**: the agent tells the user each command (test, git, build) and waits for confirmation. Standard mode (auto-execute) is unavailable. CI mode is unavailable. Autonomous mode is unavailable.

### No filesystem

- **Hard stop**: the Orchestrator informs the user that DevFlow requires a persistent filesystem and cannot operate. This is the only primitive with no graceful fallback.

---

## When to Re-probe

The environment is probed **once per cycle** at Step 0. Capabilities do not change mid-cycle. If the user switches editors mid-cycle, they should start a new cycle.

Standalone agents (invoked outside the full lifecycle) can run `devflow-ctl capabilities` at their Step 1 to determine what's available, since they don't benefit from the Orchestrator's probe.

---

## Anti-Patterns

- ❌ **Detect model capabilities** — DevFlow does not classify, route, or recommend models. The probe is of the *environment* (editor + tools), not the model. What model runs is the user's decision.
- ❌ **Assume a primitive is available** — always check the probe results in `context.md` before using an environment-dependent feature. If the primitive is `no` or `unknown`, use the fallback.
- ❌ **Break the cycle when a primitive is missing** — the framework degrades gracefully. The only hard stop is `filesystem: no`.
- ❌ **Re-probe mid-cycle** — capabilities are stable within a cycle. Re-probing wastes time and can cause inconsistent behavior if the environment changes.
- ❌ **Hide the degradation from the user** — the Orchestrator informs the user what's active and what's degraded at Step 0, so the user understands the environment they're operating in.

---

## Agents That Apply This Pattern

| Agent | When | What it checks |
|-------|------|----------------|
| **Orchestrator** (Phase 0) | Session initialization | Runs the probe, records in `context.md`, informs user of active/degraded features |
| **Architect** (Phase 3) | Before parallel exploration | `subagents` — if yes, dispatch parallel; if no, sequential |
| **Implementer** (Phase 5) | Before parallel task dispatch and verifier dispatch | `subagents` — if yes, dispatch parallel; if no, sequential |
| **Reviewer** (Phase 6) | Before parallel review and visual diff | `subagents` for parallel review; `vision` for visual diff |
| **Standalone agents** | Step 1 | All relevant primitives for their features |

See each agent's SKILL.md for the specific check location.
