# Feature Plan Template

Save to `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md`:

> This is the **intermediate plan artifact**. After implementation, Step 8 overwrites this file with the final feature report using [feature-template.md](./feature-template.md).

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

### Tasks

> Tasks are ordered by dependency. Each task follows TDD: Red (test first) → Green (production code).

#### Task 1: {title}

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

Review the plan at `docs/devflow/features/YYYY-MM-DD-{slug}-feature.md`.
If approved, the Feature Agent will implement each task following TDD (Red → Green).
```
