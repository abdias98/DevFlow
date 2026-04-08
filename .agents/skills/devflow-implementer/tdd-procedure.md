# TDD Procedure — Red→Green Cycle

## Standard Flow (Stack Mode = no)

For each task in the plan:

### 🔴 Red Phase (tests first)
1. Read the task's `🧪 Tests for this Task` section from the plan
2. Copy the complete test code exactly as written — do NOT redesign it
3. Create the test file using `create_file` or add to existing with `replace_string_in_file`
4. Run the test command from the plan → verify tests **FAIL**
   - If a test passes immediately → the feature already exists; flag to the user
   - Register tests in session memory test-registry (status: FAIL)

### 🟢 Green Phase (production code)
5. **Read the target file** (if modifying existing)
6. **Apply the production code change**
7. **Run the same tests** → verify they now **PASS**
8. **Track progress:**
   - Tests PASS → update test-registry (PASS ✅), mark step complete, continue
   - Tests FAIL unexpectedly → stop, document failure, consider invoking debugger
9. **Commit at task checkpoints:**
   ```bash
   git add {specific files from plan}
   git commit -m "{message from plan}"
   ```

## After All Tasks

1. Run the **full test suite** (not just new tests)
2. Verify NO regressions — all pre-existing tests still pass
3. If regressions detected → fix them before proceeding

## Handling Failures

| Situation | Action |
|-----------|--------|
| Test fails after applying code | Re-read the step, check for typos. If correct, invoke debugger |
| File doesn't exist | Check if prior step should have created it. Flag to user |
| Merge conflict | Read full current file, adjust replacement strings |
| Build error | Read error output, fix, re-run |
| Max 3 retries per step | After 3 attempts, stop and ask user |
