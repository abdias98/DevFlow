# TDD Procedure — Red→Green Cycle

> **Standard Mode (Pair Mode: no):** Auto-execute tests and git commands. See `rules.md` → `## Implementation Modes`.
> **Pair Mode (Pair Mode: yes):** Tell user the commands and wait for confirmation. NEVER auto-execute.
> **CI Mode (CI=true):** Same as Standard mode — auto-execute.

## Standard Flow (Stack Mode = no)

For each task in the plan:

### 🔴 Red Phase (test creation)
1. Read the task's `🧪 Tests for this Task` section from the plan.
2. Copy the complete test code exactly as written — do NOT redesign it.
3. Create the test file using `create_file` or add to existing with `edit`.
4. **Standard mode:** Auto-execute the test to confirm it fails (red):
   > `{Test Command (single file)} {test path}`
   - If the test PASSES unexpectedly → the feature already exists. Flag to user and skip this task.
   - If the test FAILS → proceed. This is the expected red phase.
5. **Pair mode:** Tell the user to run the test. Do NOT auto-execute.
6. Register tests in session memory `test-registry.md` (status: FAIL expected → updated after Green).

### 🟢 Green Phase (production code)
7. Read the target file (if modifying existing).
8. Apply the production code change using `create_file` or `edit`.
9. **Standard mode:** Auto-execute the test to confirm it passes (green):
   > `{Test Command (single file)} {test path}`
   - If PASS → update `test-registry.md` (PASS), update `traceability.md` (fill Impl File, Status = ✅ DONE).
   - If FAIL → stop, re-read the step for typos. If correct, invoke Debugger.
10. **Pair mode:** Tell the user to run the test. Wait for user to report result.
11. **Pair Mode gate (if `Pair Mode: yes` in `phase-state.md`):**
    - After the task completes successfully, STOP and present the changes.
    - Ask: *"Task {N}/{M} complete: {task title}. Files: {list}. Review and approve?"*
    - Options: ✅ Approve → commit and continue, ✏️ Revise → redo Green Phase, ❌ Cancel → stop.
    - Wait for explicit user approval before proceeding to the next task.
12. **Standard mode:** Auto-commit with the planned message:
    ```bash
    git add {files}
    git commit -m "{planned message}"
    ```
13. **Pair mode:** Tell the user the commit command and message.

## After All Tasks

**Standard mode:** Auto-execute the full test suite:
> `{Test Command}`
- If all pass → proceed to Reviewer.
- If regressions → fix before proceeding.

**Pair mode:** Tell the user: "All tasks implemented. Run the full test suite to verify no regressions: `{Test Command}`"

## Handling Failures

| Situation | Action |
|-----------|--------|
| Test fails after applying code | Re-read the step, check for typos. If correct, suggest invoking debugger. |
| File doesn't exist | Check if prior step should have created it. Flag to user. |
| Merge conflict | Read full current file, adjust replacement strings. |
| Build error | Ask user for the error output, fix accordingly. |
| Max 3 retries per step | After 3 attempts, stop and ask user. |
