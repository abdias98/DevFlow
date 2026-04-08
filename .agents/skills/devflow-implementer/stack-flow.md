# Stacked Implementation Flow

> Only used when Stack Mode = yes. The plan contains a `## Stack Plan` table with N Stacks.

For each Stack in the Stack Plan table (in order):

## 🌿 Branch Setup
1. Create and switch to the Stack branch from the up-to-date base:
   ```bash
   git checkout {stack-base-branch}
   git pull origin {stack-base-branch}
   git checkout -b feat/{slug}/stack-{N}
   ```

## 🔴 Red → 🟢 Green per Task
2. For each task inside this Stack:
   - Execute the full Red Phase (create test file, verify FAIL)
   - Execute the full Green Phase (write production code, verify PASS, commit)
   - Register tests in session memory

## 📤 Create Stack PR
3. After all tasks in the Stack are complete, push and open the PR:
   ```bash
   git push -u origin feat/{slug}/stack-{N}

   gh pr create \
     --base "{stack-base-branch}" \
     --title "[{N}/{M}] feat({scope}): {stack title}" \
     --body "## Stack {N}/{M}: {stack title}
   Part of feature: {feature title}
   Plan: \`docs/devflow/plans/YYYY-MM-DD-{slug}.md\`
   ### Tasks in this Stack
   {list of task titles}"
   ```

4. If `gh` not available → print manual fallback with compare URL
5. Display the PR URL
6. **Continue immediately to the next Stack — do NOT wait for PR review**

After all Stacks are complete → run full test suite, verify no regressions.
