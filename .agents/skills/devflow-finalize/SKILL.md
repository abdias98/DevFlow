---
name: devflow-finalize
description: "Produces the final clean solution summary, verifies all tests pass and BLOCK review findings are resolved, explains how to run/test, lists possible improvements, and cleans session memory. USE WHEN: completing a feature, wrapping up implementation, final summary, devflow finalize phase."
argument-hint: "Feature slug or description. Auto-reads session memory."
---

# DevFlow Finalizer

You are the **Finalizer** sub-agent. Wrap up a completed development cycle with verification, summary, and cleanup.

## Rules

- Read [common rules](<{{SKILLS_DIR}}/shared/rules.md>) — language detection, tool fallback, file persistence, **Scope-Locking**, **Test Execution Policy**.
- Read [Git Conventions](<{{SKILLS_DIR}}/shared/standards/git-conventions.md>) — the generated PR description follows its PR rules (§5) and Commit Checkpoints (§3).
- **NEVER begin if tests are failing** — route to Debugger first.
- **NEVER begin if BLOCK findings are unresolved** — route to Implementer first.
- **Respect the active mode for command execution** (tests, dependency audit, git) — mirror the Implementer's policy (`rules.md` → Implementation Modes and CI/CD Mode):
  - **Standard mode (`Pair Mode: no`) / CI mode (`CI=true`):** auto-execute the verification commands (full test suite, audit).
  - **Pair mode (`Pair Mode: yes`):** tell the user the command and wait for their reported result — NEVER auto-execute.
  - Resolve the mode with `devflow-ctl config get pair_mode --slug {slug}` and the `CI` env var. `git push` / `gh pr create` are NEVER auto-executed in any mode.
- **Present in clear, user-facing format.** Be concise but complete.
- **Flow Artifacts Exception:** The final summary saved at `docs/devflow/summaries/` is always allowed, consistent with `rules.md`.

---

## Procedure

### Step 1 — Read Session State

Read session memory: `context.md` (feature, slug, Stack Mode), `phase-state.md` (phases, artifacts), `test-registry.md` (test status).

### Step 2 — Verify Completion

1. **Tests, build, lint, typecheck — on the final tree, from the evidence ledger:**
   - **Standard / CI mode:** run `devflow-ctl evidence run --kind test` and `devflow-ctl evidence run --kind build` (exit 2 *no command configured* → the project has no such command; move on). Never run `{Test Command}` by hand and read the result — that is the claim this step exists to replace.
   - **Pair mode:** ask the user — *"Run the full test suite: `{Test Command}` (and `{Build Command}` if the project has one) and paste the output."* Save each to `docs/devflow/session/{slug}/evidence/pasted-{kind}.txt` and record it with `devflow-ctl evidence attest --kind {kind} --file <that file>`.
   - Then **`devflow-ctl evidence check --kind test,build,lint,typecheck --slug {slug}`**. Exit 1 → STOP before any cleanup: a failing test or build routes to the Debugger; stale or missing lint/typecheck evidence routes to the Implementer to re-run its gate. Exit 2 → no Stack Profile in the session — run Quick Stack Detection, then repeat.
   - Copy every line that is not a plain `✔ … passed` into the summary's **Verification** section: `–` (not configured — not verified), *attested by the user*, and *waived* — a waived kind is also added to `context.md` → `## Accepted Risks` (timestamp, kind, the user's reason), which the archive step below carries into the report.
2. **Review:** Check the latest review document in `docs/devflow/reviews/` (all `-review-r{N}.md` passes if re-reviews happened — every pass's BLOCKs must be resolved or explicitly dismissed, not just absent from the last file). If BLOCK findings remain unresolved → STOP, route to Implementer.
3. **Deferred backlog:** Re-read the review document for any `🟠 INCOMPLETE` finding. Run `devflow-ctl backlog list --area {this cycle's scope}` and confirm every one of them has a matching entry — an INCOMPLETE finding must never vanish when session memory is cleaned. If one is missing (e.g., the Reviewer's step was skipped), run `devflow-ctl backlog add {file} "{reason}" --severity incomplete` for it now, before proceeding.
4. **DoD:** Verify each criterion from `context.md`. Flag any unverifiable items to the user — **in CI / Autonomous mode**, log them to `send-to-user.md` instead of waiting.
5. **Dependencies:** Run `devflow-ctl scan sca` (mode-aware — see Rules) — the same deterministic, language-agnostic dependency-vulnerability audit the Validation Gate already uses, so both gates report through one path instead of two uncorrelated mechanisms:
   - **Standard / CI mode:** auto-execute the read-only command and read the result.
   - **Pair mode:** ask the user — *"Run `devflow-ctl scan sca`. Report any vulnerabilities found."*
    - Critical/High vulnerabilities → 🔴 BLOCK: STOP, route to Implementer to fix before release (same policy as Reviewer — `devflow-ctl scan` findings are never optional). Do NOT proceed to summary or session cleanup with a known critical/high CVE.
   - The command skips gracefully when no supported manifest or audit tool is found — note that explicitly rather than silently omitting the check.
   - Record the finding (or the skip reason) in the final summary's Quality section (Step 4) — including non-blocking findings, so they aren't silently lost between here and the summary.
6. **Stack branches** *(if Stack Mode = yes)*: Verify all expected branches exist (ask user to confirm with `git branch`).
7. **Traceability gate (pre-deletion, non-bypassable):** Run `devflow-ctl traceability check docs/devflow/session/{slug}/traceability.md` (mode-aware — auto-execute in Standard/CI, ask user in Pair). If it exits non-zero (coverage < 100%) → STOP, route to Implementer to complete or justify pending rows. NEVER proceed to session cleanup (Step 5.5) with traceability below 100% — the deletion is irreversible and would destroy the evidence needed to remediate.

### Step 3 — Collect Artifacts

Gather:
- All files created and modified (from plan file map and commits).
- All test files added (from `test-registry.md`).
- All document paths (spec, plan, review, mockups).
- Update plan checkboxes to `[x]` for completed tasks.
- **Compute quality metrics** using the [metrics template](<{{SKILLS_DIR}}/shared/metrics-template.md>):
  - Read the review → count BLOCK/WARN/INFO + extract top categories.
  - Read `test-registry.md` → count tests, first-pass rate.
  - Read `context.md` → DoD coverage.
  - Run `devflow-ctl traceability check docs/devflow/session/{slug}/traceability.md` → coverage percentage (do not count rows yourself).
  - Fill all remaining values in `docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md`.
  - Run `devflow-ctl metrics aggregate docs/devflow/metrics/YYYY-MM-DD-{slug}-metrics.md` — it appends the row to `_aggregate.md` and recomputes the 4 Averages that have a real column behind them (cycle duration, BLOCKs, test pass rate, total cycles). Do NOT recompute these by reading the table yourself. "Most frequent BLOCK category" and "Phase with most retries" have no structured column to derive from — the command leaves them as a manual entry; fill or update them yourself from this cycle's review/iteration data if you have something concrete to add.
- **Escape analysis** ([escape-analysis.md](<{{SKILLS_DIR}}/shared/escape-analysis.md>)): ask the user — *"Did the previous cycle in this area receive any external correction (a PR review comment, a QA bug, an incident) since it was approved?"* **In CI / Autonomous mode**, skip the question and record `Escapes after APPROVED: 0 (unverified — no user present)`; the next interactive cycle re-checks. If yes, classify each one (class + layer, per the doc) and run `devflow-ctl escape add --class <class> --layer <layer> --ref "<ref>" --note "<note>" --slug <that cycle's slug>` for it — the escape belongs to the cycle that approved the code, not to this one. In Standard/CI mode, a PR reference is read read-only the way [Intake Mode](<{{SKILLS_DIR}}/devflow-review/SKILL.md>) → Step 1 reads it, and proposed to the user for classification before recording; never write back to the PR. When `escape add` reports a **framework layer**, also record or re-see the lesson in the framework memory, in the abstract ([escape-analysis.md](<{{SKILLS_DIR}}/shared/escape-analysis.md>) → What Recording One Does, step 4). Fill this cycle's own `Escapes after APPROVED` metric from the result (0 if none). Skip silently if this is the area's first cycle.
- **Append to knowledge base** (`docs/devflow/knowledge-base/learnings.md`):
  - If Step above recorded any escape, add its anti-pattern to By Topic and Cycle History alongside the cycle's own patterns — same dedup rule.
  - Extract reusable patterns from the Architect's spec (design patterns, component structures).
  - Extract anti-patterns from the Reviewer's BLOCK/WARN findings.
  - Record key architecture decisions from the spec's Design Decisions section.
  - **Add to BOTH sections:**
    - **By Topic** — add patterns under the relevant topic (Testing, Security, Architecture, Performance, Stack-Specific). If the topic section is empty, create it. If a pattern already exists there, append the new cycle slug as a source. This is the primary section agents read.
    - **Cycle History** — add a chronological entry under `### {slug} — {date}` with the full set of patterns, anti-patterns, and decisions. This is the traceability log.
  - **Deduplication rule:** if a pattern or anti-pattern already exists in By Topic from a previous cycle, do NOT duplicate it — instead, append the new cycle slug to the existing entry's source list. Only add a new entry if the pattern is genuinely new.
- **Feed the framework memory** ([framework-memory.md](<{{SKILLS_DIR}}/shared/framework-memory.md>) → Capture, At every close): classify **every** pattern and anti-pattern written to `learnings.md` this cycle — not only the stack ones — with the table in framework-memory.md → Stack patterns, and record each where it belongs, in the abstract (the privacy guard refuses this project's names and paths):
  - about the **stack** → `devflow-ctl memory add --type stack-pattern --stack {stack}`, or `memory seen {id}` when `memory query --type stack-pattern` already has it;
  - about **DevFlow** — a defect found after this cycle's review approved it (by the user, in a runtime check, in QA) that a layer had what it needed to catch (the Verifier, the Reviewer, the plan's tests, a standard that does not exist) → `devflow-ctl escape add --class … --layer … --ref "<where it was found>" --note "…" --slug {slug}`, then escape-analysis.md → What Recording One Does, step 4; a step, tool or template that misled the agent → a `correction` or `friction` entry;
  - about **this codebase** → `learnings.md` only.
  Then mark each of those entries in `learnings.md` with the result (framework-memory.md → Capture, Marks), so the next close can tell what was already classified. Run `devflow-ctl knowledge sync` — it takes your edits into the project's knowledge store (memory-conventions.md → Persistent Artifacts) and re-renders the file — and then `devflow-ctl artifacts check learnings docs/devflow/knowledge-base/learnings.md --slug {slug}` — exit 1 names the lessons still unmarked, or the missing *By Topic* / *Cycle History* structure; fix them before going on. The first sync of a `learnings.md` written in the old per-cycle layout imports each cycle as a Cycle History entry; its *By Topic* section starts empty — propose the topic grouping to the user (same lessons, regrouped, nothing dropped) and write it only with their approval. If sync reports the file was **not rendered from the current store** and saved it as `learnings.md.unsynced`, re-apply what that copy has and the regenerated view lacks, then sync again.
  - Run `devflow-ctl memory friction report` and propose each recurring pattern it lists to the user as a `friction` entry.
  - Run `devflow-ctl memory sync`. If it reports the project view (`docs/devflow/knowledge-base/framework-memory.md`) changed, say so in the final summary and leave committing it to the user — never commit it yourself.
- **Update the standards profile** (`docs/devflow/knowledge-base/standards-profile.md`) when this cycle introduced or changed a convention — a new place a responsibility lives, a new primitive, a new idiom for a standard, or a deviation that was fixed. Update the affected rows in place with a canonical example from this cycle and set *Last updated*. If the profile does not exist, recommend `/devflow-templates standards-profile` in the final summary instead of creating it here. The `knowledge sync` of Step 5 takes the edit into the project store.
- **Update project template** (`docs/devflow/templates/project-architecture.md`):
  - Merge patterns discovered in this cycle into the project template.
  - If the file doesn't exist yet, invoke `devflow-templates` to generate it from accumulated artifacts.
  - This accelerates future cycles by providing a project-specific architecture reference.

### Step 4 — Generate Final Summary

1. Present the summary using the [summary template](<{{SKILLS_DIR}}/devflow-finalize/summary-template.md>).
2. Run `devflow-ctl traceability check docs/devflow/session/{slug}/traceability.md` and include its Coverage Summary output in the final report — do not recount the rows yourself.
3. **Use `create_file` to save** the final summary to `docs/devflow/summaries/YYYY-MM-DD-{slug}-summary.md`.
4. Include the Stack branches table if Stack Mode = yes.
5. **Generate a PR description** — produce a ready-to-use PR description from the cycle artifacts and present it to the user:

```markdown
## {Feature title}

### Summary
{1-2 sentence summary from the spec's Spec Digest or the context.md Goal}

### Changes
- {N} files created, {M} files modified
- {list of key files with one-line description each}

### Tasks
- {N} tasks implemented (TDD: Red→Green per task)
- {N} tests added ({unit/integration/e2e breakdown})

### Quality
- Review: {APPROVED | CHANGES REQUESTED → resolved} ({B} BLOCKs, {W} WARNs, {I} INFOs resolved)
- DoD: {N}/{N} criteria met
- Verification (`devflow-ctl evidence check`): {all passed on the final tree | list each `–` not configured, attested and waived kind}
- Dependency audit (`devflow-ctl scan sca`): {clean | N critical/high found — see detail | skipped: reason}
{ - Visual diff: {checked / skipped (no vision)} *(if UI feature)*}

### Artifacts
- Spec: `docs/devflow/specs/{file}`
- Plan: `docs/devflow/plans/{file}`
- Review: `docs/devflow/reviews/{file}`
- Summary: `docs/devflow/summaries/{file}`

### Test plan
- Run: `{Test Command}`
- Single file: `{Test Command (single file)} {test paths}`
```

Present this to the user: *"Here's a PR description you can use when creating the pull request:"* followed by the PR description block. The user copies it — DevFlow never creates the PR automatically. Then run `devflow-ctl pr register --slug {slug}` (on the cycle's branch; `--branch` names another): it records which branch this cycle produced, so its PR — and the review comments it gets — can be traced back to the cycle after the session is gone. Close with one line: *"When this PR gets reviewed, `devflow-ctl pr poll` (or the watch job, `/devflow-review intake watch start`) collects the comments, and `devflow-ctl status` lists them; run `/devflow-review intake --pending` to bring them back into DevFlow."*

### Step 5 — Archive & Clean Session Memory

1. **Archive validation report** (if not already done by the Orchestrator):
    - Use the canonical archive path recorded in `phase-state.md` by the Orchestrator — do NOT recompute the date (it may differ past midnight, which would fork two divergent archives).
    - If NOT present: copy `docs/devflow/session/{slug}/validation-report.md` to that path before deleting. Overwrite an existing archive only when its content hash differs.
    - If accepted risks exist in `context.md` under `## Accepted Risks`: ensure they are in the archived report.
2. **Archive autonomous-mode artifacts, if present.** If `docs/devflow/session/{slug}/autonomous-log.md` or `send-to-user.md` exist (autonomous mode was active this cycle), copy each to `docs/devflow/summaries/YYYY-MM-DD-{slug}-autonomous-log.md` / `-send-to-user.md` before deleting — see [memory conventions](<{{SKILLS_DIR}}/shared/memory-conventions.md>). If neither file exists, skip this step.
3. Confirm with the user that all artifacts are saved and the feature is complete. **In CI / Autonomous mode:** do NOT wait — auto-confirm, log the artifact checklist to `send-to-user.md` as the deliverable record, and proceed.
4. **Make sure the store has this cycle's lessons**: run `devflow-ctl knowledge sync` once more, so any edit to `learnings.md` since Step 3 reaches the project's knowledge store before the session is deleted. The store lives outside the project, under the framework memory's local registry: a branch switch, a stash or a lost `docs/devflow/` no longer takes the lessons with it — the next sync, or the next `devflow-ctl init`, writes the file again. It never blocks the close: an unavailable store only warns.
5. **Release the lock, then delete the whole session directory** (`docs/devflow/session/{slug}/`) — run `devflow-ctl lock release --slug {slug}`, then remove the directory itself, not a hand-picked file list. If `lock release` fails, STOP and report — do NOT delete the directory while the lock is held (it would orphan a live lock). This is deliberate: a fixed list of filenames (`context.md`, `phase-state.md`, ...) silently leaves behind anything not on it — exactly how `autonomous-log.md` and `send-to-user.md` were orphaned before this fix. Deleting the directory guarantees nothing survives that wasn't archived in steps 1–4.

### Step 6 — Final Confirmation

Tell the user:
```
✅ DevFlow cycle complete: {feature-slug}

Artifacts saved:
  Spec:   docs/devflow/specs/{filename}
  Plan:   docs/devflow/plans/{filename}
  Review: docs/devflow/reviews/{filename}
  Summary: docs/devflow/summaries/{filename}

Session memory cleaned. Feature is ready.
```

---

Follow the [output format](<{{SKILLS_DIR}}/shared/output-format.md>) for your response structure.