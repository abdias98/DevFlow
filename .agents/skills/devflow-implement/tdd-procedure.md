# TDD Procedure — Red→Green Cycle (Without Executing Tests)

## Standard Flow (Stack Mode = no)

For each task in the plan:

### 🔴 Red Phase (test creation)
1. Read the task's `🧪 Tests for this Task` section from the plan.
2. Copy the complete test code exactly as written — do NOT redesign it.
3. Create the test file using `create_file` or add to existing with `replace_string_in_file`.
4. Inform the user with the exact command to run the test (from the plan), e.g.:
   > "Test created at {path}. To verify it fails (red phase), run: `{Test Command (single file)} {path}`"
5. **DO NOT run the test.** If a test passes immediately when the user runs it, the feature already exists — flag to the user.
6. Register tests in session memory `test-registry.md` (status: FAIL expected).

### 🟢 Green Phase (production code)
7. Read the target file (if modifying existing).
8. Apply the production code change using `create_file` or `replace_file_content`.
9. Inform the user how to verify the test now passes:
   > "Production code written. To verify the test passes, run: `{Test Command (single file)} {test path}`"
10. Track progress:
    - If the user reports tests pass → update `test-registry.md` (PASS), mark step complete, continue.
    - If the user reports failure → stop, document failure, consider invoking debugger.
11. Commit at task checkpoints with the message from the plan.

## After All Tasks

1. Provide the command to run the **full test suite** (not just new tests):
   > "All tasks implemented. Run the full test suite to verify no regressions: `{Test Command}`"
2. If the user reports regressions → fix them before proceeding. Do NOT run tests yourself.

## Handling Failures

| Situation | Action |
|-----------|--------|
| User reports test fails after applying code | Re-read the step, check for typos. If correct, suggest invoking debugger. |
| File doesn't exist | Check if prior step should have created it. Flag to user. |
| Merge conflict | Read full current file, adjust replacement strings. |
| Build error | Ask user for the error output, fix accordingly. |
| Max 3 retries per step | After 3 attempts, stop and ask user. |