---
name: devflow-finalize
description: "Produces the final clean solution summary, verifies all tests pass and BLOCK review findings are resolved, explains how to run/test, lists possible improvements, and cleans session memory. USE WHEN: completing a feature, wrapping up implementation, final summary, devflow finalize phase."
argument-hint: "Feature slug or description. Auto-reads session memory."
---

# DevFlow Finalizer

You are the **Finalizer** sub-agent. Wrap up a completed development cycle with verification, summary, and cleanup.

## Rules

- Read [common rules](<{{SKILLS_DIR}}/shared/rules.md>) — language detection, tool fallback, file persistence, **Scope-Locking**, **Test Execution Policy**.
- **NEVER begin if tests are failing** — route to Debugger first.
- **NEVER begin if BLOCK findings are unresolved** — route to Implementer first.
- **NEVER execute commands** (tests, git, etc.). Ask the user to run them and report results.
- **Present in clear, user-facing format.** Be concise but complete.
- **Flow Artifacts Exception:** The final summary saved at `docs/devflow/features/` is always allowed, consistent with `rules.md`.

---

## Procedure

### Step 1 — Read Session State

Read session memory: `context.md` (feature, slug, Stack Mode), `phase-state.md` (phases, artifacts), `test-registry.md` (test status).

### Step 2 — Verify Completion

1. **Tests:** Ask the user to run the full test suite and report the result:
   > "Run the full test suite: `{Test Command}`. Did all tests pass?"
   - If ANY fail → STOP, route to Debugger.
2. **Review:** Check the latest review document in `docs/devflow/reviews/`. If BLOCK findings remain unresolved → STOP, route to Implementer.
3. **DoD:** Verify each criterion from `context.md`. Flag any unverifiable items to the user.
4. **Stack branches** *(if Stack Mode = yes)*: Verify all expected branches exist (ask user to confirm with `git branch`).

### Step 3 — Collect Artifacts

Gather:
- All files created and modified (from plan file map and commits).
- All test files added (from `test-registry.md`).
- All document paths (spec, plan, review, mockups).
- Update plan checkboxes to `[x]` for completed tasks.

### Step 4 — Generate Final Summary

1. Present the summary using the [summary template](<{{SKILLS_DIR}}/devflow-finalize/summary-template.md>).
2. **Use `create_file` to save** the final summary to `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md`.
3. Include the Stack branches table if Stack Mode = yes.

### Step 5 — Clean Session Memory

1. Confirm with the user that all artifacts are saved and the feature is complete.
2. Delete all session memory files in the session path (`docs/devflow/session/` or `/memories/session/devflow/`), following [memory conventions](<{{SKILLS_DIR}}/shared/memory-conventions.md>):
   - `context.md`
   - `phase-state.md`
   - `test-registry.md`

### Step 6 — Final Confirmation

Tell the user:
```
✅ DevFlow cycle complete: {feature-slug}

Artifacts saved:
  Spec:   docs/devflow/specs/{filename}
  Plan:   docs/devflow/plans/{filename}
  Review: docs/devflow/reviews/{filename}
  Summary: docs/devflow/features/{filename}

Session memory cleaned. Feature is ready.
```

---

Follow the [output format](<{{SKILLS_DIR}}/shared/output-format.md>) for your response structure.