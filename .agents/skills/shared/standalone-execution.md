# Standalone Execution — Canonical Pattern

> **Framework-centric principle:** every standalone agent (Feature, Bug-Fixer, Refactorer, Performance, Migration, Contract, Documentation, Template, Tutorial, Reverse) runs the same shape of cycle — understand, plan, get approval, apply, verify, report, review — with the same execution modes, the same rollback and iteration guarantees, and the same session-closing order. This document is the single source of truth for that shape. Agent-specific SKILL.md files supply only what is genuinely specific to them (their template, their complexity gate, their analysis steps) and reference this file for everything else. When a rule here changes, every standalone agent inherits the fix without touching 10 files.

This document defines the canonical pattern referenced by `devflow-feature`, `devflow-bug-fix`, `devflow-refactor`, `devflow-perf`, `devflow-migrate`, `devflow-contract`, `devflow-docs`, `devflow-templates`, `devflow-tutorial`, and `devflow-reverse`.

**Placeholders used below** — each SKILL.md substitutes its own values:

| Placeholder | Meaning | Example (`devflow-feature`) |
|---|---|---|
| `{agent}` | Human-readable agent name | `Feature Agent` |
| `{mode}` | Value passed to `devflow-ctl init --mode` | `feature` |
| `{artifact-dir}` | Directory for this agent's persistent artifacts | `docs/devflow/features/` |
| `{artifact-noun}` | Singular noun for the artifact | `feature` |
| `{branch-type}` | Branch prefix per [git-conventions.md](./standards/git-conventions.md) §2 | `feat` |
| `{plan-suffix}` / `{report-suffix}` | Filename suffixes that keep the plan and the final report as two distinct files | `-feature-plan.md` / `-feature.md` |

**Branch type mapping** (git-conventions.md §2 defines `feat/fix/refactor/perf/chore/docs`; not every standalone agent has a dedicated type):

| Agent | `{mode}` | `{branch-type}` |
|---|---|---|
| Feature Agent | `feature` | `feat` |
| Bug-Fixer | `bug-fix` | `fix` |
| Refactorer | `refactor` | `refactor` |
| Performance Agent | `perf` | `perf` |
| Documentation Agent | `docs` | `docs` |
| Migration Agent | `migrate` | `chore` |
| Contract Agent | `contract` | `chore` |
| Template Agent | `templates` | `chore` |
| Tutorial Agent | `tutorial` | `chore` |
| Reverse Agent | `reverse` | `chore` |

> The five agents mapped to `chore` have no dedicated type in git-conventions.md — `chore` is its catch-all for tooling/maintenance work. If a future standard revision adds dedicated types for them, update this table, not each SKILL.md.

---

## 1. Step 0 — Session Opening

Every standalone agent opens its session the same way, before doing anything else:

1. **Check for an active lifecycle cycle:** run `devflow-ctl lock check`. If it reports a non-stale lock held by another cycle, STOP and inform the user — do not touch session memory.
2. **Initialize the standalone session:** run `devflow-ctl init --mode {mode} --slug {slug} --scope {glob}` with one `--scope` per file/pattern the agent will touch. Read-only agents that never write production files pass no `--scope` (they still need a session for lock, capabilities, and metrics).
3. **Read the environment capability probe:** run `devflow-ctl capabilities` and record results in `context.md` under `## Environment Capabilities`. Use `subagents: yes` to decide whether a verifier subagent replaces inline self-review (§7); use `vision: yes` to know the Reviewer will attempt a visual diff for UI-affecting work.
4. **Read the knowledge base** (`docs/devflow/knowledge-base/learnings.md`) — read the **By Topic** section relevant to this task. Check for implementation patterns, anti-patterns, and known pitfalls before doing anything else.
5. Read `## Stack Profile` from `context.md`. If not found, perform [Quick Stack Detection](./stack-detection.md) and write it.
6. **Initialize metrics:** create `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` using the [metrics template](./metrics-template.md) — *Standalone Agent Metrics Format* — with the started timestamp, `Agent: {agent}`, slug, and stack. Leave quality values empty until §9.

---

## 2. Mode Selection

Every standalone agent that writes production code or runs commands supports the same three execution modes as the lifecycle (`rules.md` → Implementation Modes, CI/CD Mode):

| Mode | Activation | Tests | Lint | Git commits | Iterations |
|------|-----------|-------|------|-------------|------------|
| **Pair** (default) | User selects 🤝 at the approval gate | Inform command, wait for pasted results | Inform command | Inform commands | Per procedure |
| **Standard** | User selects ✅ Standard at the approval gate | Auto-run + verify | Auto-run | Auto-execute | Normal |
| **CI** | `CI=true` env var at start | Auto-run + verify | Auto-run | Auto-execute | Max 1 (fail fast) |

- Record the selected mode with `devflow-ctl config set pair_mode {true|false}` at the approval gate (CI mode sets `pair_mode false` automatically).
- **Pair mode hard rule:** a Green phase MUST NOT be committed until the user pastes test output confirming PASS. A Red phase MUST be confirmed FAILING before any production code is written.
- **CI fail-fast:** in CI mode, pass `--max 1` to every `devflow-ctl iterate` call (or export `DEVFLOW_MAX_ITERATIONS=1`) — any failed check or test exits the run instead of looping.
- Git `push` and `gh pr create` are NEVER auto-executed in any mode, by any agent.
- **Read-only agents** (no production writes — e.g. an agent whose entire output is a report) skip the test/lint columns; only the approval-gate and iteration columns apply, if the agent has an approval gate at all (see §3).

---

## 3. Approval Gate

Any standalone agent that will write production files (code, migrations, generated tests, `AGENTS.md`, documentation that overwrites existing content) MUST stop after persisting its plan and ask for explicit approval, with **all four options handled** — no option may be offered without a defined next step:

| header | question | type |
|--------|----------|------|
| `{mode}_confirmation` | The plan has been saved at `{path}`. Proceed? | options: ✅ Approve — Standard (auto-run), 🤝 Approve — Pair (manual), ✏️ Modify plan, ❌ Cancel |

- **✅ Approve — Standard** → `devflow-ctl gate set plan_approval approved` + `devflow-ctl config set pair_mode false` → proceed to implementation.
- **🤝 Approve — Pair** → `devflow-ctl gate set plan_approval approved` + `devflow-ctl config set pair_mode true` → proceed to implementation.
- **✏️ Modify plan** → collect the user's feedback. Run `devflow-ctl iterate plan_revision` — exit 1 (limit reached) means STOP and escalate to the user instead of looping. On exit 0, regenerate the plan incorporating the feedback, re-persist it (overwriting the plan file, never the final report), and re-present this same gate. This mirrors the Orchestrator's Confirmation Gate handling of `✏️ Request changes` (`devflow/SKILL.md` → Confirmation Gate).
- **❌ Cancel** → `devflow-ctl lock release` and stop. Session memory is preserved (not cleaned) so the plan remains available for reference.

**CI exception:** if `CI=true` was detected at Step 0, skip this question entirely. Log "CI mode: plan auto-approved.", run `devflow-ctl gate set plan_approval approved` and `devflow-ctl config set pair_mode false`, then proceed directly to implementation.

**Read-only agents** that produce only a report (no production writes) MAY skip this gate — there is nothing to approve before the fact. State this explicitly in the agent's own SKILL.md ("read-only agent — no approval gate required") rather than silently omitting it.

---

## 4. Branch Policy

A work branch is ALWAYS created before the first production-file write (never for read-only agents), matching lifecycle Standard Mode:

- **Standard/CI:** auto-execute `git checkout -b {branch-type}/{slug}` before the first task. If the user named a custom branch during approval, use it instead.
- **Pair:** give the user the exact command and wait for confirmation that the branch is active before writing any code.
- Commits land on this branch; `push` remains manual in every mode, always.

---

## 5. Rollback Checkpoint

Before the FIRST production-file write, record a rollback point:

- **Standard/CI:** auto-execute `git rev-parse HEAD` and run `devflow-ctl checkpoint set pre-{mode}-impl {sha}`.
- **Pair:** ask the user to run `git rev-parse HEAD` and report the SHA, then record it the same way.

If implementation must be abandoned mid-way, offer the user:
> "To revert all code changes and return to the pre-implementation state, run: `git reset --hard {sha}`" (get the SHA with `devflow-ctl checkpoint get pre-{mode}-impl`). NEVER execute `git reset` yourself.

---

## 6. Iteration Limits

Every retry loop — fixing a failing test, resolving a BLOCK from self-review or the Reviewer, revising the plan — goes through `devflow-ctl iterate {loop}`, never a hand-counted "try again" in prose:

| Loop | Used for |
|---|---|
| `implement_debug` | A test fails after a Green-phase fix attempt |
| `implement_review` | Self-review or Reviewer BLOCK findings need another pass |
| `plan_revision` | User requests plan changes at the approval gate (§3) |

Exit 1 means the limit is exhausted: STOP iterating and escalate to the user with the failing output — never retry the same fix expecting a different result.

---

## 7. Lint / Typecheck Gate

Before self-review or verifier dispatch (§8), run the project's `Lint Command` from `## Stack Profile` (including any typecheck script the project defines) scoped to the changed files where possible:

- **Standard/CI:** auto-run it. Fix mechanical failures (formatting, unused imports) in-scope and re-run. Report persistent violations as findings rather than hand-waving them.
- **Pair:** inform the user of the exact command and wait for pasted output before continuing.

---

## 8. Verification — Self-Review or Verifier Subagent

The verification method depends on environment capabilities and plan size:

**If `subagents: yes` AND the plan is non-trivial (2+ tasks OR more than 3 files affected):** dispatch a **fresh-context verifier subagent** following [verifier-subagent.md](./verifier-subagent.md). It reads the plan and modified files from scratch (no inherited agent bias), checks structural completeness / scope compliance / plan compliance / obvious issues, and returns a verdict. Act on findings: fix BLOCKs and re-verify (via `iterate implement_review`), note WARNs for the Reviewer.

**Otherwise (inline self-review):** run a critical self-review — security, naming, SOLID, Clean Architecture, performance, and an honesty check ("would I critique this if a colleague wrote it?"). Fix in-scope BLOCKs via `iterate implement_review`; if the fix needs a file outside the plan, do NOT fix it — add an INFO note and mention it in the final report.

---

## 9. Canonical Closing Order

**This is the fix for a recurring defect (F01): session memory being destroyed before the steps that still need to read it.** The order below is mandatory and MUST NOT be reordered:

```
1. Verify Definition of Done → fill the report's DoD section
2. Persist the final report to {artifact-dir} (report-suffix, never overwriting the plan)
3. Auto-invoke the Reviewer — wait for its verdict
4. Resolve any BLOCK findings (iterate implement_review; escalate on exit 1)
5. Record metrics (needs the Reviewer's BLOCK/WARN/INFO counts and iteration count)
6. Write back to the knowledge base (§10)
7. ONLY NOW: devflow-ctl lock release, then delete docs/devflow/session/{slug}/
```

The session (`context.md`, `phase-state.md`, scope list) MUST stay alive through steps 3–6 — they all read or write it. Releasing the lock and deleting the session directory is always the LAST action of the cycle, never a step in the middle of it.

---

## 10. Knowledge Base Write-Back

Every standalone agent that reads the knowledge base at Step 0 (§1.4) MUST also contribute to it — reading without writing means the next cycle in the same area repeats the same mistakes:

- Extract reusable patterns applied successfully (implementation patterns, strategies specific to the agent's domain).
- Extract anti-patterns from any BLOCK/WARN findings raised by self-review or the Reviewer.
- **Add to BOTH sections** of `docs/devflow/knowledge-base/learnings.md`:
  - **By Topic** — under the relevant topic (Testing, Security, Architecture, Performance, Stack-Specific). Create the topic section if missing.
  - **Cycle History** — a chronological entry `### {slug} — {date}` with the patterns and anti-patterns found.
  - **Deduplication rule:** if a pattern already exists in By Topic, do NOT duplicate it — append this cycle's slug to the existing entry's source list instead.
- If there is genuinely nothing new worth recording, skip the write-back and note that explicitly in the metrics file — do not fabricate a pattern to fill the section.

---

## Anti-Patterns

- ❌ **Releasing the lock or deleting the session before the Reviewer has returned a verdict** — the exact defect §9 exists to prevent (F01).
- ❌ **Offering `✏️ Modify plan` without a defined handler** — every option at the approval gate must have a next step (F31).
- ❌ **Declaring `NEVER run tests` as an absolute rule** — test execution is mode-dependent (§2); an absolute rule breaks CI mode.
- ❌ **Counting retries in prose** ("try again up to 2 times") instead of `devflow-ctl iterate` — this is what causes double-counting against the Orchestrator's own limits and makes the limit unenforceable.
- ❌ **Skipping the branch/checkpoint because "it's just a small fix"** — the policy applies regardless of task size, exactly like lifecycle Standard Mode.
- ❌ **Reading the knowledge base without ever writing to it** — turns "cross-cycle learning" into "cross-cycle amnesia" for every standalone agent that does this.
- ❌ **Copying this pattern's prose into each SKILL.md** — reference this file; when the pattern changes, every agent must inherit the fix without a 10-file edit.
