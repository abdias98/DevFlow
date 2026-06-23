# Task Supervisor — Canonical Pattern

> **Framework-centric principle:** when the Implementer dispatches parallel task subagents, a lightweight supervisor verifies each subagent's output against the plan **per-wave** (not post-waves like the Verifier). The supervisor has fresh context — it does not inherit the Implementer's bias. It catches plan deviations, scope violations, and cross-task interface mismatches before the Implementer commits, so fixes are cheap.

This document defines the canonical pattern for supervising task subagents within the Implementer (Phase 5). The Implementer references this file and dispatches supervisor checks after each wave's task subagents complete.

---

## When to Dispatch a Supervisor

**Dispatch a supervisor when ALL of these hold:**
- The wave has **2+ tasks** (with 1 task there is no cross-task consistency to check).
- The environment supports `subagents: yes` (from [environment-probe.md](./environment-probe.md)).
- The plan has **3+ tasks total** (for smaller plans, the Verifier post-waves is sufficient).

**Skip the supervisor when ANY of these hold:**
- The wave has **1 task** (the Implementer can verify inline — read the work packet, check the files).
- The plan has **1-2 tasks total** (the Verifier post-waves covers this).
- Stack Mode = yes (stacked flow has its own ordering — parallel dispatch does not apply).
- `subagents: no` (sequential fallback — the Implementer does inline self-checks with context reset).

---

## The Pattern

### 1. After task subagents complete, dispatch supervisor checks

Once all task subagents in a wave return their completion reports, the Implementer dispatches **per-task supervisor checks** (parallel, fresh context each) **before** synthesizing and committing.

### 2. Per-task supervisor check

Each check is a fresh-context subagent. It does NOT inherit the Implementer's reasoning or the task subagent's reasoning. It reads the plan's work packet for that task and the files the task declared, then verifies.

**Brief format:**

| Field | Content |
|-------|---------|
| **Goal** | Verify task {N} implementation matches its work packet and stays in scope. |
| **Context** | **READ:** plan.md (ONLY task {N}'s work packet section — Goal, Acceptance criteria, Deliverables), {list of files declared in task N's deliverables}. **DO NOT READ:** other tasks' sections, the full plan, context.md, standards, the Implementer's reasoning. |
| **Constraints** | Read-only. Do NOT run tests. Do NOT edit files. Check against **acceptance criteria** (NOT implementation guide — the guide is a guide, the criteria are the contract). Run `devflow-ctl scope check {file}` for each modified file. |
| **Output format** | Findings table + verdict (see below). |

**Three verification axes:**

1. **Plan compliance** — Does the implementation satisfy the task's acceptance criteria? For each criterion: is it met, partially met, or missing? Missing criteria → BLOCK. Partially met → WARN.
2. **Scope compliance** — Run `devflow-ctl scope check {file}` for each file the task subagent reported as modified. Any file outside declared scope → BLOCK. Files in the plan's File Map for this task → PASS.
3. **Obvious issues** — Syntax errors visible in the code (unbalanced braces, missing imports within the same file). Broken imports (file references something that doesn't exist). TODO/FIXME left in production code → WARN.

**Output format:**

```markdown
## Supervisor Check — Task {N}

**Verdict:** PASS | PASS_WITH_WARNINGS | FAIL

| # | Severity | Axis | File | Finding |
|---|----------|------|------|---------|
| 1 | BLOCK | Scope | src/config.ts | Modified outside declared scope. |
| 2 | WARN | Plan | src/auth.ts | Acceptance criteria "documented" not met — missing JSDoc on `login()`. |
| 3 | INFO | Obvious | — | All imports resolve. No TODOs. |
```

**Severity scale:**
- **BLOCK** — the task's acceptance criteria are not met, scope is violated, or the code is broken. The Implementer MUST fix before committing this wave.
- **WARN** — a non-blocking issue. The Implementer notes it for the Reviewer via `### Additional Recommendations`.
- **INFO** — observation. No action needed.

### 3. Cross-task consistency check

After all per-task checks complete, dispatch one **cross-task consistency check** (fresh context). This check verifies that the tasks in the wave produced consistent interfaces and no conflicts.

**Brief format:**

| Field | Content |
|-------|---------|
| **Goal** | Verify that tasks in wave {N} produced consistent interfaces and no conflicts. |
| **Context** | **READ:** plan.md (File Map + all task deliverables in wave {N}), {all files modified in wave N}. **DO NOT READ:** previous waves, context.md, standards. |
| **Constraints** | Read-only. Do NOT run tests. Do NOT edit files. Check: imports resolve across tasks, no conflicting changes to shared files, interfaces match (function signatures, type exports, API contracts between tasks). |
| **Output format** | Findings table + verdict (see below). |

**Verification axes:**

1. **Interface consistency** — If task A creates a function/type/API that task B imports or uses, do the names, signatures, and shapes match? Mismatch → BLOCK.
2. **File conflicts** — Did two tasks in the same wave modify the same file? (Should not happen — wave grouping prevents this — but verify.) Conflict → BLOCK.
3. **Shared dependencies** — If both tasks import from a shared module, did one task modify that module in a way that breaks the other's import? Breakage → BLOCK.

**Output format:**

```markdown
## Cross-Task Check — Wave {N}

**Verdict:** CONSISTENT | INCONSISTENT

| # | Severity | Task A | Task B | Finding |
|---|----------|--------|--------|---------|
| 1 | BLOCK | T1 | T2 | T1 exports `createUser()`, T2 imports `create_user()` — name mismatch. |
| 2 | INFO | — | — | No file conflicts. No shared dependency breakage. |
```

### 4. Implementer's response to findings

After all supervisor checks and the cross-task check return:

- **Any BLOCK (per-task or cross-task):**
  1. Fix the issue(s) in the affected task's files.
  2. Re-dispatch the supervisor check for that specific task (fresh context) to confirm the fix.
  3. If the cross-task check had a BLOCK, re-dispatch it after fixing.
  4. Once all BLOCKs are resolved → synthesize and commit.
  5. If a BLOCK cannot be fixed without plan amendment → STOP and ask the user.

- **Only WARN/INFO:**
  1. Note WARNs in `### Additional Recommendations` for the Reviewer.
  2. Note INFOs for the Reviewer's awareness.
  3. Synthesize and commit.

- **All PASS / CONSISTENT:**
  1. Synthesize and commit.

### 5. Synthesis (unchanged from current)

After supervisor findings are resolved:

1. Verify all tasks completed successfully (files exist, tests pass in Standard mode).
2. **Standard mode:** auto-commit each task sequentially with the planned message.
3. **Pair mode:** present all tasks in the wave for user approval.
4. Proceed to the next wave.

---

## Relationship to Other Verification Layers

| Layer | When | What it checks | Scope | Context |
|-------|------|----------------|-------|---------|
| **Task Supervisor** (this pattern) | After each wave | Plan compliance per task + cross-task consistency | Per-wave | Fresh, narrow (work packet + task files) |
| **Verifier** ([verifier-subagent.md](./verifier-subagent.md)) | After ALL waves | Structural completeness global + scope global + plan compliance global | All waves | Fresh, broader (full plan + all files) |
| **Reviewer** (Phase 6) | After Verifier passes | Code quality, security, performance, architecture alignment, visual diff | All changed files | Fresh, full (diff + spec + plan + standards) |

**No overlap:** The supervisor catches per-task deviations early (cheap fix). The verifier catches global structural issues post-waves. The reviewer catches quality/security/performance issues with full standards loading.

**Example of how they complement:**
- Supervisor (Wave 1): "T2 didn't create the `validateToken()` function that acceptance criteria requires" → BLOCK → Implementer fixes → cheap.
- Verifier (post-waves): "Task 5's test file references a helper that was supposed to be created in Task 1 but the file doesn't exist" → BLOCK → caught after all waves but before Reviewer.
- Reviewer (Phase 6): "The `validateToken()` function doesn't check for expired tokens — Security standard §3 → BLOCK" → caught with full standards analysis.

---

## Fallback: Sequential Execution (no subagents)

If `subagents: no` in `context.md` → `## Environment Capabilities`:

The Implementer performs **inline self-checks** with a deliberate context reset after each task:

1. **After each task (sequential):**
   - Set aside the implementation reasoning.
   - Re-read the plan's work packet for this task.
   - Check: acceptance criteria met? scope OK (`devflow-ctl scope check`)? obvious issues?
   - Note findings. Fix BLOCKs before proceeding to the next task.

2. **After each wave (even in sequential mode):**
   - Re-read all task deliverables in this wave.
   - Check: interfaces consistent? imports resolve across tasks? no file conflicts?
   - Note findings. Fix BLOCKs before committing.

The inline fallback is identical in substance — the key is the **context reset**, not the dispatch mechanism. The supervisor's value comes from looking at the task with fresh eyes, not from being a separate process.

---

## Anti-Patterns

- ❌ **Supervisor checks against the implementation guide** — the guide is a guide, not a contract. Check against **acceptance criteria**. The task subagent may have found a better implementation than the guide suggests — that's fine if the criteria are met.
- ❌ **Supervisor loads standards** — the supervisor checks plan compliance and scope, not code quality. Standards loading is the Reviewer's job. Loading standards in the supervisor wastes tokens and blurs the layer separation.
- ❌ **Supervisor runs tests** — test execution is the user's responsibility (Pair mode) or auto-run (Standard mode). The supervisor is static analysis only.
- ❌ **Skip the cross-task check for 2-task waves** — even 2 tasks can have interface mismatches. The cross-task check is cheap (~2K tokens) and catches the most expensive bugs (integration failures).
- ❌ **Re-dispatch supervisor for WARN/INFO** — only re-dispatch for BLOCK. WARN/INFO are noted for the Reviewer and don't require re-verification.
- ❌ **Supervisor replaces the Verifier** — they are complementary. Supervisor = per-wave (granular, catches early). Verifier = post-waves (global, catches structural). Both run.

---

## Agents That Apply This Pattern

| Agent | Application |
|-------|-------------|
| **Implementer** (Phase 5) | Dispatches supervisor checks after each wave's task subagents complete, before synthesizing and committing. |

See the Implementer's `SKILL.md` → Step 2b for the specific integration point.
