# Feature Plan Template

Save to `docs/devflow/features/YYYY-MM-DD-{slug}-feature-plan.md`:

> This is the **intermediate plan artifact** and a persistent audit record of what the user approved. After implementation, the final report is written to `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md` (a SEPARATE file) using [feature-template.md](./feature-template.md). NEVER overwrite this plan file.

```markdown
## ⚡ Feature Plan: {slug}

**Date:** YYYY-MM-DD
**Agent:** DevFlow Feature Agent ⚡
**Stack:** {Language} · {Framework} · {Test Runner}

### Plan Digest

> 5-10 line summary that the Reviewer reads first. If it answers their questions, they skip reading the full plan.

- **Tasks:** {N} tasks
- **Files to create:** {list}
- **Files to modify:** {list}
- **Key dependencies:** {task A → task B, or "none"}
- **Test strategy:** {unit per task, or "manual verification"}
- **Scope:** {what's explicitly out of scope}

### Summary

**Goal:** {one sentence}

**Definition of Done:**
- [ ] {criterion 1}
- [ ] {criterion 2}

### Scope

- **In:** {what's included — files, components, behavior}
- **Out:** {what's explicitly excluded}

### Reference Implementation

- **File/Pattern:** `{path}` — {what to replicate: structure, naming, imports, test style}

### Affected Files

**Create:**
- `{path}` — {purpose}

**Modify:**
- `{path}` — {what changes and why}

### Behavior Scenarios

> From the Understanding Summary's Behavior Scenarios ([behavior-scenarios.md](<{{SKILLS_DIR}}/shared/behavior-scenarios.md>)). Each one is owned by a task and has a sequence test in that task. Write `None — {reason}` if the feature has no transitions.

| # | Given | When | Then | Task | Test file |
|---|-------|------|------|------|-----------|

### Tasks

> Tasks are ordered by dependency. Each task follows TDD: Red (test first) → Green (production code).

#### Task 1: {title}

- **Standards constraints:** `{standard}.md §{N}` — {the concrete rule for this task} *(one line per standard the task applies to; run each one's Implementation Self-Check before the task is done)*

- [ ] **Test file:** `{path/to/test.ext}`
  ```{language}
  {Complete test code — ready to paste. Use detected test framework conventions.
  Must include all imports, setup, and assertions that will FAIL before production code exists.}

  // ✅ Happy path
  {test for normal expected behavior}

  // ⚠️ Edge case
  {test for boundary or unexpected input}

  // ❌ Failure / error scenario
  {test that verifies correct error handling}

  // 🔁 Sequence / interaction scenario — S{N} (only for scenarios this task owns)
  {test that drives the unit through the scenario's event sequence and asserts the final observable outcome}
  ```

- [ ] **Production code:** `{path/to/file.ext}` *(create / modify)*
  ```{language}
  {Minimal production code. Only what makes the tests pass.
  If modifying an existing file, show only the changed section with surrounding context.}
  ```

- [ ] **Commit:**
  ```bash
  git add {files}
  git commit -m "feat({scope}): {task description}"
  ```

  **Test command:** `{Test Command (single file)} {test path}`

---

#### Task 2: {title}

*(repeat the same structure for each task)*

---

### Verification

**All new tests:** `{Test Command (single file)} {test paths}`
**Full suite:** `{Test Command}`

---

## 🚦 Confirmation

Review the plan at `docs/devflow/features/YYYY-MM-DD-{slug}-feature-plan.md`.
If approved, the Feature Agent will implement each task following TDD (Red → Green).
```
