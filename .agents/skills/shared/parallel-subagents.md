# Parallel Subagents — Canonical Pattern

> **Framework-centric principle:** parallelism is orchestrated by the framework, not by the model. The framework identifies independent subtasks, dispatches them as subagents, and synthesizes their outputs. Any model that can follow the lifecycle can operate within this pattern. When the editor does not support subagent invocation, the framework falls back to sequential execution — the synthesis step is identical, only the execution order changes.

This document defines the canonical pattern for dispatching parallel subagents within DevFlow. Agents that benefit from parallelism (Architect, Implementer, Reviewer, and any standalone agent with independent exploration axes) reference this file and apply the pattern to their specific phase.

---

## When to Parallelize

**Parallelize when ALL of these hold:**
- The subtasks are **independent** — no subtask's output is required as input for another subtask to start.
- The subtasks have **bounded scope** — each can be completed with a defined set of files/context, not the entire codebase.
- The synthesis step is **well-defined** — you know in advance how to combine the subagents' outputs into a unified result.

**Do NOT parallelize when:**
- Subtasks have **data dependencies** (one needs the other's output to begin).
- The subtasks are so small that the **dispatch overhead exceeds the benefit** (e.g., reading two files — just read them sequentially).
- The subtasks share mutable state that would create **race conditions** (rare in read-only exploration; common when writing files — never parallelize writes to the same file).

---

## The Pattern

### 1. Decompose into independent subtasks

Identify the independent axes of work. Each subtask becomes a **subagent brief**:

| Field | Content |
|-------|---------|
| **Goal** | What this subagent should produce (one sentence) |
| **Context** | Files to read, prior decisions, spec/plan sections relevant to this subtask |
| **Constraints** | Read-only? Scope limits? Standards to apply? |
| **Output format** | How the subagent should report back (structured summary, findings list, etc.) |

### 2. Dispatch subagents and continue working

Dispatch each subagent with its brief. If the editor supports parallel subagent invocation, dispatch them concurrently and continue working on synthesis prep while they run. If not, run them sequentially — the briefs are the same.

> **Long-lived subagents:** for multi-step subtasks, keep the subagent alive across steps rather than re-dispatching. This preserves context and saves cost through cache reads. Only terminate when the subtask is complete.

### 3. Synthesize outputs

Collect each subagent's output and synthesize into a unified result. The synthesis is the orchestrating agent's responsibility — the subagents do not see each other's outputs. The synthesis step:
- Resolves any conflicts between subagent findings (e.g., two subagents flagged the same file from different angles — consolidate).
- Prioritizes by severity (BLOCK > WARN > INFO).
- Produces the final artifact (spec section, review verdict, implementation summary).

---

## Fallback: Sequential Execution

If the editor or environment does not support parallel subagent invocation:

> **Check first:** the Orchestrator records environment capabilities in `context.md` → `## Environment Capabilities` at Step 0 (see [environment-probe.md](./environment-probe.md)). If `subagents: no`, sequential fallback is the **default path**, not a fallback — the agent runs subtasks inline from the start.

1. Execute each subtask's brief **sequentially** in any order (they are independent).
2. Collect outputs as each completes.
3. The synthesis step is **identical** — only the execution order changed.

This fallback is automatic. Agents do not need to detect the environment; they attempt dispatch and, if the editor runs subagents sequentially, the result is the same (just slower). The framework never breaks because parallelism is unavailable.

---

## Context Freshness

For **verification** subagents (see [verifier-subagent.md](./verifier-subagent.md)), fresh context is critical: the verifier should NOT inherit the implementer's working context, because confirmation bias hides problems. A fresh-context verifier reads the spec, plan, and modified files from scratch and reports independently.

For **exploration** subagents (Architect's codebase scan), context freshness is less critical — they read the codebase anyway. But each exploration subagent should have a **narrow scope** so they don't duplicate work.

---

## Anti-Patterns

- ❌ **Parallelize everything** — dispatching subagents for trivial tasks wastes tokens and time. Only parallelize when the subtasks are genuinely independent and bounded.
- ❌ **Parallelize writes to the same file** — race conditions corrupt the file. Never dispatch two subagents that modify the same file concurrently.
- ❌ **Skip synthesis** — subagent outputs are raw material, not the final result. The orchestrating agent MUST synthesize.
- ❌ **Inherit context for verification** — a verifier with the implementer's context has confirmation bias. Use fresh context (see [verifier-subagent.md](./verifier-subagent.md)).

---

## Agents That Apply This Pattern

| Agent | Application | Subtasks |
|-------|-------------|----------|
| **Architect** (Phase 3) | Parallel codebase exploration | Structure, Dependencies, Test patterns, Reference implementations |
| **Implementer** (Phase 5) | Parallel independent tasks | Tasks with no inter-task dependency |
| **Reviewer** (Phase 6) | Parallel multi-dimension review | Security, Performance, Architecture + plan compliance |
| **Reverse Agent** (standalone) | Parallel reverse-engineering | Architecture, Dependencies, API endpoints |
| **Performance Agent** (standalone) | Parallel bottleneck analysis | Profiling, N+1 detection, Memory leak inspection |

See each agent's SKILL.md for the specific subtask decomposition.
