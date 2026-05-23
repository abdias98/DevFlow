# Stacked Implementation Flow

> Only used when Stack Mode = yes. The plan contains a `## Stack Plan` table with N Stacks.

For each Stack in the Stack Plan table (in order):

## 🌿 Branch Setup (Manual — User Creates)
1. **Inform the user** to create and switch to the Stack branch. **NEVER run git commands yourself.**
   > "Create the Stack branch with:
   > ```bash
   > git checkout {stack-base-branch}
   > git pull origin {stack-base-branch}
   > git checkout -b feat/{slug}/stack-{N}
   > ```
   > Confirm when ready so I can proceed with implementation."

2. **STOP and wait** for the user to confirm the branch is ready before proceeding.

## 🔴 Red → 🟢 Green per Task
3. For each task inside this Stack:
   - Read the task's test code from the plan.
   - Create the test file using `create_file` and tell the user the exact command to run it (do NOT run it).
   - Write the production code using `create_file` or `replace_file_content`.
   - Tell the user the test command again to verify it now passes.
   - Commit with the planned message.
   - Register tests in session memory (`test-registry.md`).
   - Update `traceability.md`: fill Impl File paths and set Status = ✅ DONE for this task's rows.

## 📤 Branch and PR (Manual)
4. After all tasks in the Stack are complete, **inform the user** of the branch and how to push and create a PR manually:
   ```
   Stack {N}/{M} complete on branch feat/{slug}/stack-{N}.
   To share this work:
     git push -u origin feat/{slug}/stack-{N}
   Then create a PR from that branch to {stack-base-branch} with title:
     [{N}/{M}] feat({scope}): {stack title}
   ```
   **NEVER run `gh pr create` or any equivalent.** The user decides if and when to open PRs.

5. **Continue immediately to the next Stack** — do NOT wait for PR review. Go back to step 1 for the next Stack.

After all Stacks are complete → provide the full test suite command and recommend the user run it to verify no regressions.