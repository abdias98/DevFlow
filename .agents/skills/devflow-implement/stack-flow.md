# Stacked Implementation Flow

> Only used when Stack Mode = yes. The plan contains a `## Stack Plan` table with N Stacks.

For each Stack in the Stack Plan table (in order):

## 🌿 Branch Setup

**Standard mode (Pair Mode: no):**
1. Auto-execute branch creation:
   ```bash
   git checkout {stack-base-branch}
   git pull origin {stack-base-branch}
   git checkout -b feat/{slug}/stack-{N}
   ```
2. **Continue immediately** — no user confirmation needed.

**Pair mode (Pair Mode: yes):**
1. Tell the user: "Create the Stack branch with:" (show the git commands above).
2. **STOP and wait** for the user to confirm the branch is ready before proceeding.

## 🔴 Red → 🟢 Green per Task

For each task inside this Stack:
   - Follow the [TDD procedure](<{{SKILLS_DIR}}/devflow-implement/tdd-procedure.md>).
   - **Standard mode:** Auto-execute tests, auto-commit.
   - **Pair mode:** Tell user commands, wait for confirmation, pause after each task.

## 📤 Branch and PR (Manual)

After all tasks in the Stack are complete, inform the user of the branch and how to push and create a PR manually:
```
Stack {N}/{M} complete on branch feat/{slug}/stack-{N}.
To share this work:
  git push -u origin feat/{slug}/stack-{N}
Then create a PR from that branch to {stack-base-branch} with title:
  [{N}/{M}] feat({scope}): {stack title}
```
**NEVER auto-create PRs.** The user decides if and when to open PRs.

Continue immediately to the next Stack — go back to 🌿 Branch Setup for the next Stack.

After all Stacks are complete → auto-execute the full test suite and verify no regressions.
