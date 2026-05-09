# Plan Document Template

> **For agentic workers:** Use devflow-implement (Red→Green per task) → devflow-review to execute this plan task-by-task.

**Goal:** {One-sentence summary}
**Architecture:** {Brief reference to spec document path}
**Mockup:** `docs/devflow/mockups/YYYY-MM-DD-{slug}-mockup.html` *(UI features only — omit for backend/CLI/library)*
**Tech Stack:** {Detected from workspace}

---

## File Map

> Adapt section headings to the project's actual architecture. Examples below — use only the layers that exist in the detected stack.

**Modify:**
- `path/to/file` — description of change

**Create:**
- `path/to/new-file` — purpose

*(For web projects, group by Backend / Frontend. For Android, group by layer: Data / Domain / Presentation. For PHP/Laravel, group by: Controllers / Models / Views / Migrations. For CLI, group by: Commands / Services / Config. Adapt as needed.)*

---

### Task N: {Title}

> **Risk:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW — {one-line reason from spec's Risk Assessment} *(omit if LOW and no special notes)*
> **Affects existing:** {list of features/files that currently use what this task modifies, or "None"} *(include if Impact flag set in context.md)*
> **Reference implementation:** `{path/to/similar-existing-file}` — {what to replicate from it} *(from codebase exploration)*

**Files:**
- Modify: `path/to/file`
- Create: `path/to/new-file`

- [ ] **Step 1: {Action}**
{Clear instructions + complete code snippet}

- [ ] **Step 2: {Action}**
{Clear instructions + complete code snippet}

- [ ] **Step N: Commit**
```bash
git add {specific files}
git commit -m "{conventional commit message}"
```

#### ♿ Accessibility (if UI task)
- [ ] All interactive elements have `aria-label` or visible label
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1 for text)
- [ ] No keyboard traps
*(Omit this section for non-UI tasks)*

#### ⏪ Rollback (if HIGH-risk task)
```bash
{Exact command(s) to revert this task's changes if something goes wrong}
```
*(Omit this section for LOW/MEDIUM risk tasks)*

#### 🧪 Tests for this Task

**Test file:** `{path/to/feature.test.ext}` *(create new / add to existing)*

```{language}
{Complete, ready-to-paste test code using the detected test framework and conventions.
Must include:
  - All required imports, use statements, annotations, or setup methods
  - Test class/function/block structure matching the project's existing patterns
  - At least one test per scenario below
  - Assertions that will FAIL because the production code doesn't exist yet

Example structure varies by stack:
  - JS/TS (Jest/Vitest): describe + test/it blocks, expect assertions
  - PHP (PHPUnit): class extending TestCase, public test methods, $this->assert*
  - Python (pytest): functions prefixed test_, assert statements
  - Java/Android (JUnit): @Test annotated methods, assertEquals/assertTrue
  - .NET (xUnit/NUnit): [Fact]/[Test] annotated methods, Assert class}

// ✅ Happy path
{test for normal expected behavior}

// ⚠️ Edge case
{test for boundary or unexpected input}

// ❌ Failure / error scenario
{test that verifies correct error handling}
```

**Run command:**
```bash
{exact command to execute only these tests, adapted to the detected stack}
```

> ⚠️ All tests above MUST fail on first run (red phase). They will pass after the production code is implemented.

---

### Self-Review Checklist
- [ ] All spec requirements are covered
- [ ] Each task has a commit checkpoint
- [ ] Code snippets are complete (not partial)
- [ ] Each task has a `🧪 Tests for this Task` section with complete, runnable test code
- [ ] Each test section has at least one happy path, one edge case, one failure scenario
- [ ] Each test section includes the exact run command
- [ ] Test code uses the detected test framework and follows project conventions
- [ ] Dependencies between tasks are respected
- [ ] No orphan files (everything referenced exists)
- [ ] HTML wireframe mockup generated (UI features only) — saved to `docs/devflow/mockups/`
